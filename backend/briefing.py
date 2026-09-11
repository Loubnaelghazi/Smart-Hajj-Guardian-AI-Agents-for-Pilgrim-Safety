"""Bilingual, grounded incident briefing. AI ranks facts; it cannot invent facts."""
import json
import os
from datetime import datetime, timezone
from typing import TypedDict
import httpx
from fastapi import APIRouter, HTTPException
from langgraph.graph import StateGraph, END
from .repositories import IncidentRepository, PilgrimRepository, SafeZoneRepository
from .database import db
from .mobile_observations import tracking_entry

router = APIRouter()

def fact(key, en, ar):
    return {'id': key, 'en': en, 'ar': ar}

def collect_facts(incident, pilgrim, observation, zone, now):
    raw = incident.model_dump(mode='json')
    status = raw['status']
    statuses = {
        'OPEN': ('The incident is open; no agency acknowledgment is recorded.', 'البلاغ مفتوح؛ لم يُسجّل إقرار الوكالة باستلامه بعد.'),
        'ACKNOWLEDGED': ('The agency acknowledged the incident. This does not confirm physical assistance.', 'أقرّت الوكالة باستلام البلاغ. هذا لا يؤكد وصول المساعدة ميدانياً.'),
        'RESOLVED': ('The incident is marked resolved in the agency system.', 'تم وضع علامة «تم الحل» على البلاغ في نظام الوكالة.'),
    }
    en, ar = statuses.get(status, ('Incident status is unavailable.', 'حالة البلاغ غير متاحة.'))
    facts = [fact('status', en, ar)]
    levels = {'LOW': 'منخفض', 'MEDIUM': 'متوسط', 'HIGH': 'مرتفع', 'CRITICAL': 'حرج'}
    level = raw.get('risk_level', 'UNKNOWN')
    facts.append(fact('risk', f'Recorded incident risk: {level}. This is the incident assessment, not a new safety check.', f'مستوى الخطر المسجّل في البلاغ: {levels.get(level, "غير معروف")}. هذا تقييم البلاغ وليس فحص سلامة جديداً.'))
    entry = tracking_entry(pilgrim, observation, zone, now) if pilgrim else {'status': 'no_location'}
    o = entry.get('observation')
    if not o:
        facts.append(fact('location', 'No phone location is available for this briefing.', 'لا يتوفر موقع من الهاتف لهذا الملخص.'))
    elif entry['status'] == 'stale':
        facts.append(fact('location', 'The last phone location is stale. Current position and distance are not confirmed.', 'آخر موقع من الهاتف قديم. الموقع والمسافة الحاليان غير مؤكّدين.'))
    else:
        accuracy = round(o['accuracy_m'])
        distance = o.get('distance_to_meeting_point_m')
        if distance is not None:
            facts.append(fact('location', f'Phone GPS places the pilgrim about {round(distance)} m from the meeting point, with accuracy ±{accuracy} m.', f'يشير موقع الهاتف إلى بُعد الحاج نحو {round(distance)} متر عن نقطة التجمّع، بدقة ±{accuracy} متر.'))
        else:
            facts.append(fact('location', 'A recent phone position is available, but no meeting-point distance is configured.', 'يتوفر موقع حديث من الهاتف، لكن مسافة نقطة التجمّع غير متاحة.'))
        if o.get('mocked'):
            facts.append(fact('mock', 'This position is marked as a mock location; it is demonstration evidence.', 'هذا الموقع مُعلّم كموقع تجريبي، ويُستخدم لأغراض العرض.'))
        if not o.get('usable_for_distance') and zone:
            facts.append(fact('accuracy', 'GPS accuracy is insufficient for separation scoring.', 'دقة الموقع غير كافية لتقييم الابتعاد عن المجموعة.'))
    facts.append(fact('network', 'Live operator reachability and congestion are not verified by this briefing. Check the original safety evidence.', 'لا يتحقق هذا الملخص من إمكانية الوصول عبر المشغّل أو الازدحام الحالي. راجع بيانات فحص السلامة الأصلية.'))
    return facts

class BriefingState(TypedDict, total=False):
    facts: list
    ordered: list
    mode: str
    reason: str

async def prioritize(state: BriefingState):
    facts = state['facts']
    fallback = {'ordered': facts, 'mode': 'evidence_summary', 'reason': 'provider_not_configured'}
    url, key, model = (os.getenv(k, '').strip() for k in ('BRIEFING_API_URL', 'BRIEFING_API_KEY', 'BRIEFING_MODEL'))
    if not all((url, key, model)):
        return fallback
    # Send no names, phone numbers, identifiers or exact coordinates to the model.
    prompt = 'Prioritize these verified facts for an agency incident briefing. Return only a JSON object with fact_ids: an array containing every supplied id exactly once, most important first. Do not add facts, instructions, or change incident status. Facts: ' + json.dumps([{'id': f['id'], 'text': f['en']} for f in facts])
    try:
        async with httpx.AsyncClient(timeout=12) as client:
            response = await client.post(url, headers={'Authorization': f'Bearer {key}'}, json={
                'model': model, 'messages': [{'role': 'user', 'content': prompt}],
                'response_format': {'type': 'json_object'},
            })
            response.raise_for_status()
            result = json.loads(response.json()['choices'][0]['message']['content'])
        ids = result['fact_ids']
        lookup = {f['id']: f for f in facts}
        if not isinstance(ids, list) or len(ids) != len(lookup) or any(not isinstance(i, str) for i in ids) or set(ids) != set(lookup):
            raise ValueError('Invalid evidence references')
        return {'ordered': [lookup[i] for i in ids], 'mode': 'ai_prioritized', 'reason': None}
    except Exception:
        return {**fallback, 'reason': 'provider_unavailable_or_invalid_output'}

graph = StateGraph(BriefingState)
graph.add_node('prioritize_verified_evidence', prioritize)
graph.set_entry_point('prioritize_verified_evidence')
graph.add_edge('prioritize_verified_evidence', END)
briefing_agent = graph.compile()

@router.post('/api/incidents/{incident_id}/briefing')
async def incident_briefing(incident_id: str):
    incident = IncidentRepository.get(incident_id)
    if not incident:
        raise HTTPException(404, 'Incident not found')
    pilgrim = PilgrimRepository.get(incident.pilgrim_id)
    observation = db.mobile_observations.find_one({'_id': pilgrim.phone_number}, {'_id': 0}) if pilgrim else None
    zone = SafeZoneRepository.get_by_group(pilgrim.group_id) if pilgrim else None
    now = datetime.now(timezone.utc)
    facts = collect_facts(incident, pilgrim, observation, zone, now)
    result = await briefing_agent.ainvoke({'facts': facts})
    return {'incident_id': incident.id, 'incident_status': incident.status,
            'generated_at': now.isoformat(), 'mode': result['mode'], 'reason': result.get('reason'),
            'facts': result['ordered'],
            'notice': {'en': 'A snapshot of recorded evidence. Does not change risk, send SOS, or confirm rescue.',
                       'ar': 'لقطة من البيانات المسجّلة. لا تغيّر تقييم الخطر، ولا ترسل استغاثة، ولا تؤكد وصول الإنقاذ.'}}
