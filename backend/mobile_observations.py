"""Foreground handset evidence, separate from operator verification."""
from datetime import datetime, timezone
from math import radians, sin, cos, atan2, sqrt
from typing import Literal

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field, AwareDatetime
from pymongo.errors import DuplicateKeyError
from .database import db
from .repositories import PilgrimRepository, SafeZoneRepository, AgencyRepository, GroupRepository, GuideRepository

router = APIRouter()

class Observation(BaseModel):
    phone_number: str = Field(min_length=1, max_length=64)
    latitude: float = Field(ge=-90, le=90, allow_inf_nan=False)
    longitude: float = Field(ge=-180, le=180, allow_inf_nan=False)
    accuracy_m: float = Field(gt=0, le=10000, allow_inf_nan=False)
    measured_at: AwareDatetime
    connection: list[Literal['wifi', 'mobile', 'ethernet', 'vpn', 'bluetooth', 'other', 'none']]
    mocked: bool = False

def distance_m(lat1, lon1, lat2, lon2):
    p1, p2 = radians(lat1), radians(lat2)
    a = sin((p2-p1)/2)**2 + cos(p1)*cos(p2)*sin(radians(lon2-lon1)/2)**2
    return 6371000 * 2 * atan2(sqrt(min(1, a)), sqrt(max(0, 1-a)))

def evaluate(body, zone, now):
    age = (now-body.measured_at).total_seconds()
    if age < -15 or age > 120:
        raise HTTPException(422, 'GPS timestamp is stale or in the future')
    distance = distance_m(body.latitude, body.longitude, zone.latitude, zone.longitude)
    boundary = ('inside' if distance + body.accuracy_m <= zone.radius_m else
                'outside' if distance - body.accuracy_m > zone.radius_m else 'uncertain')
    return {**body.model_dump(mode='json'), 'source': 'mock_location' if body.mocked else 'phone_gps',
            'received_at': now.isoformat(), 'distance_to_meeting_point_m': round(distance, 1),
            'zone_state': boundary, 'safe_zone_id': zone.id,
            'usable_for_distance': body.accuracy_m <= 100}

@router.post('/api/mobile/observations')
def observe(body: Observation):
    pilgrim = PilgrimRepository.get_by_phone(body.phone_number)
    if not pilgrim:
        raise HTTPException(404, 'Registered pilgrim not found')
    zone = SafeZoneRepository.get_by_group(pilgrim.group_id)
    if not zone:
        raise HTTPException(409, 'Your agency must configure a meeting point first')
    now = datetime.now(timezone.utc)
    result = evaluate(body, zone, now)
    # One latest observation per phone; no movement history is collected.
    result['measured_at'] = body.measured_at.astimezone(timezone.utc).isoformat()
    try:
        db.mobile_observations.update_one(
            {'_id': body.phone_number, '$or': [
                {'measured_at': {'$lt': result['measured_at']}},
                {'measured_at': {'$exists': False}}]}, {'$set': result}, upsert=True)
    except DuplicateKeyError:
        raise HTTPException(409, 'A newer GPS observation was already received')
    return {**result, 'safe_area': {'latitude': zone.latitude, 'longitude': zone.longitude, 'radius': zone.radius_m}}

def apply_device_distance(store, phone, fallback):
    observation = db.mobile_observations.find_one({'_id': phone}, {'_id': 0})
    if not observation:
        return fallback
    age = (datetime.now(timezone.utc)-datetime.fromisoformat(observation['measured_at'])).total_seconds()
    pilgrim = PilgrimRepository.get_by_phone(phone)
    zone = SafeZoneRepository.get_by_group(pilgrim.group_id) if pilgrim else None
    usable = -15 <= age <= 120 and observation['usable_for_distance'] and zone is not None
    if usable:
        received_at = observation['received_at']
        observation = evaluate(Observation.model_validate(observation), zone, datetime.now(timezone.utc))
        observation['received_at'] = received_at
    # Conservative lower bound: accuracy uncertainty cannot inflate separation.
    distance = max(0, observation['distance_to_meeting_point_m']-observation['accuracy_m']) if usable else None
    store.update(phone, distance_from_group_m=distance,
                 device_observation={**observation, 'stale': not usable},
                 distance_source=observation['source'] if usable else 'unavailable')
    return distance


def tracking_entry(pilgrim, observation, zone, now):
    entry = {'pilgrim_id': pilgrim.id, 'name': pilgrim.name, 'group_id': pilgrim.group_id,
             'status': 'no_location', 'observation': None}
    if not observation:
        return entry
    measured = datetime.fromisoformat(observation['measured_at'])
    age = (now-measured).total_seconds()
    fresh = -15 <= age <= 120
    public = {key: observation.get(key) for key in (
        'latitude', 'longitude', 'accuracy_m', 'measured_at', 'received_at',
        'connection', 'source', 'mocked')}
    public.update(age_seconds=max(0, round(age)), distance_to_meeting_point_m=None,
                  zone_state='unknown', usable_for_distance=False)
    if fresh and zone:
        current = evaluate(Observation.model_validate(observation), zone, now)
        for key in ('distance_to_meeting_point_m', 'zone_state', 'usable_for_distance'):
            public[key] = current[key]
    entry.update(status='fresh' if fresh else 'stale', observation=public)
    return entry


@router.get('/api/agencies/{agency_id}/tracking')
def agency_tracking(agency_id: str):
    # Same agency identity model as existing operations routes; no global phone feed.
    if not AgencyRepository.get(agency_id):
        raise HTTPException(404, 'Agency not found')
    now = datetime.now(timezone.utc)
    pilgrims = PilgrimRepository.list_by_agency(agency_id)
    groups = GroupRepository.list_by_agency(agency_id)
    zones = {group.id: SafeZoneRepository.get_by_group(group.id) for group in groups}
    observations = {row['_id']: row for row in db.mobile_observations.find(
        {'_id': {'$in': [p.phone_number for p in pilgrims]}})}
    return {
        'agency_id': agency_id, 'generated_at': now.isoformat(), 'freshness_seconds': 120,
        'guides': [{'id': g.id, 'name': g.name, 'phone_number': g.phone_number}
                   for g in GuideRepository.list_by_agency(agency_id)],
        'groups': [{'id': g.id, 'name': g.name, 'guide_id': g.guide_id,
                    'safe_zone': zones[g.id].model_dump(mode='json') if zones[g.id] else None}
                   for g in groups],
        'pilgrims': [tracking_entry(p, observations.get(p.phone_number), zones.get(p.group_id), now)
                     for p in pilgrims],
    }
