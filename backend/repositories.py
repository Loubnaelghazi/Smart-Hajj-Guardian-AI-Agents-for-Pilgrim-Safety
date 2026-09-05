from __future__ import annotations

from typing import Optional

from .database import db
from .domain_models import (
    Agency,
    Guide,
    Group,
    Incident,
    IncidentStatus,
    Pilgrim,
    SafeZone,
)


DEMO_AGENCY_ID = "demo-agency-001"
DEMO_GUIDE_ID = "demo-guide-001"
DEMO_GROUP_ID = "demo-group-001"
DEMO_PILGRIM_ID = "demo-pilgrim-001"
DEMO_PHONE_NUMBER = "+99999991000"


def _dump(model):
    return model.model_dump(mode="json")


def _clean(document):
    if document is None:
        return None
    document.pop("_id", None)
    return document


class AgencyRepository:
    collection = db.agencies

    @staticmethod
    def create(agency: Agency) -> Agency:
        AgencyRepository.collection.replace_one(
            {"id": agency.id}, _dump(agency), upsert=True
        )
        return agency

    @staticmethod
    def update(agency: Agency) -> Agency:
        return AgencyRepository.create(agency)

    @staticmethod
    def get(agency_id: str) -> Optional[Agency]:
        document = _clean(
            AgencyRepository.collection.find_one({"id": agency_id})
        )
        return Agency.model_validate(document) if document else None

    @staticmethod
    def list() -> list[Agency]:
        return [
            Agency.model_validate(_clean(d))
            for d in AgencyRepository.collection.find()
        ]

    @staticmethod
    def delete(agency_id: str) -> bool:
        result = AgencyRepository.collection.delete_one({"id": agency_id})
        return result.deleted_count > 0


class GuideRepository:
    collection = db.guides

    @staticmethod
    def create(guide: Guide) -> Guide:
        GuideRepository.collection.replace_one(
            {"id": guide.id}, _dump(guide), upsert=True
        )
        return guide

    @staticmethod
    def update(guide: Guide) -> Guide:
        return GuideRepository.create(guide)

    @staticmethod
    def get(guide_id: str) -> Optional[Guide]:
        document = _clean(
            GuideRepository.collection.find_one({"id": guide_id})
        )
        return Guide.model_validate(document) if document else None

    @staticmethod
    def list() -> list[Guide]:
        return [
            Guide.model_validate(_clean(d))
            for d in GuideRepository.collection.find()
        ]

    @staticmethod
    def list_by_agency(agency_id: str) -> list[Guide]:
        return [
            Guide.model_validate(_clean(d))
            for d in GuideRepository.collection.find(
                {"agency_id": agency_id}
            )
        ]

    @staticmethod
    def delete(guide_id: str) -> bool:
        result = GuideRepository.collection.delete_one({"id": guide_id})
        return result.deleted_count > 0


class GroupRepository:
    collection = db.groups

    @staticmethod
    def create(group: Group) -> Group:
        GroupRepository.collection.replace_one(
            {"id": group.id}, _dump(group), upsert=True
        )
        return group

    @staticmethod
    def update(group: Group) -> Group:
        return GroupRepository.create(group)

    @staticmethod
    def get(group_id: str) -> Optional[Group]:
        document = _clean(
            GroupRepository.collection.find_one({"id": group_id})
        )
        return Group.model_validate(document) if document else None

    @staticmethod
    def list() -> list[Group]:
        return [
            Group.model_validate(_clean(d))
            for d in GroupRepository.collection.find()
        ]

    @staticmethod
    def list_by_agency(agency_id: str) -> list[Group]:
        return [
            Group.model_validate(_clean(d))
            for d in GroupRepository.collection.find(
                {"agency_id": agency_id}
            )
        ]

    @staticmethod
    def delete(group_id: str) -> bool:
        result = GroupRepository.collection.delete_one({"id": group_id})
        return result.deleted_count > 0


class PilgrimRepository:
    collection = db.pilgrims

    @staticmethod
    def create(pilgrim: Pilgrim) -> Pilgrim:
        PilgrimRepository.collection.replace_one(
            {"id": pilgrim.id}, _dump(pilgrim), upsert=True
        )
        return pilgrim

    @staticmethod
    def update(pilgrim: Pilgrim) -> Pilgrim:
        return PilgrimRepository.create(pilgrim)

    @staticmethod
    def get(pilgrim_id: str) -> Optional[Pilgrim]:
        document = _clean(
            PilgrimRepository.collection.find_one({"id": pilgrim_id})
        )
        return Pilgrim.model_validate(document) if document else None

    @staticmethod
    def get_by_phone(phone_number: str) -> Optional[Pilgrim]:
        document = _clean(
            PilgrimRepository.collection.find_one(
                {"phone_number": phone_number}
            )
        )
        return Pilgrim.model_validate(document) if document else None

    @staticmethod
    def list() -> list[Pilgrim]:
        return [
            Pilgrim.model_validate(_clean(d))
            for d in PilgrimRepository.collection.find()
        ]

    @staticmethod
    def list_by_group(group_id: str) -> list[Pilgrim]:
        return [
            Pilgrim.model_validate(_clean(d))
            for d in PilgrimRepository.collection.find(
                {"group_id": group_id}
            )
        ]

    @staticmethod
    def list_by_agency(agency_id: str) -> list[Pilgrim]:
        return [
            Pilgrim.model_validate(_clean(d))
            for d in PilgrimRepository.collection.find(
                {"agency_id": agency_id}
            )
        ]

    @staticmethod
    def delete(pilgrim_id: str) -> bool:
        result = PilgrimRepository.collection.delete_one({"id": pilgrim_id})
        return result.deleted_count > 0


class SafeZoneRepository:
    collection = db.safe_zones

    @staticmethod
    def create(safe_zone: SafeZone) -> SafeZone:
        # One safe-zone per group in the current prototype.
        SafeZoneRepository.collection.delete_many(
            {"group_id": safe_zone.group_id}
        )
        SafeZoneRepository.collection.replace_one(
            {"id": safe_zone.id}, _dump(safe_zone), upsert=True
        )
        return safe_zone

    @staticmethod
    def update(safe_zone: SafeZone) -> SafeZone:
        return SafeZoneRepository.create(safe_zone)

    @staticmethod
    def get(safe_zone_id: str) -> Optional[SafeZone]:
        document = _clean(
            SafeZoneRepository.collection.find_one({"id": safe_zone_id})
        )
        return SafeZone.model_validate(document) if document else None

    @staticmethod
    def get_by_group(group_id: str) -> Optional[SafeZone]:
        document = _clean(
            SafeZoneRepository.collection.find_one({"group_id": group_id})
        )
        return SafeZone.model_validate(document) if document else None

    @staticmethod
    def list() -> list[SafeZone]:
        return [
            SafeZone.model_validate(_clean(d))
            for d in SafeZoneRepository.collection.find()
        ]

    @staticmethod
    def delete_by_group(group_id: str) -> bool:
        result = SafeZoneRepository.collection.delete_many(
            {"group_id": group_id}
        )
        return result.deleted_count > 0


class IncidentRepository:
    collection = db.incidents

    @staticmethod
    def create(incident: Incident) -> Incident:
        IncidentRepository.collection.replace_one(
            {"id": incident.id}, _dump(incident), upsert=True
        )
        return incident

    @staticmethod
    def update(incident: Incident) -> Incident:
        IncidentRepository.collection.replace_one(
            {"id": incident.id}, _dump(incident), upsert=True
        )
        return incident

    @staticmethod
    def get(incident_id: str) -> Optional[Incident]:
        document = _clean(
            IncidentRepository.collection.find_one({"id": incident_id})
        )
        return Incident.model_validate(document) if document else None

    @staticmethod
    def list() -> list[Incident]:
        return [
            Incident.model_validate(_clean(d))
            for d in IncidentRepository.collection.find()
        ]

    @staticmethod
    def list_active() -> list[Incident]:
        return [
            Incident.model_validate(_clean(d))
            for d in IncidentRepository.collection.find(
                {"status": {"$ne": IncidentStatus.RESOLVED.value}}
            )
        ]

    @staticmethod
    def list_by_agency(agency_id: str) -> list[Incident]:
        return [
            Incident.model_validate(_clean(d))
            for d in IncidentRepository.collection.find(
                {"agency_id": agency_id}
            )
        ]

    @staticmethod
    def list_by_group(group_id: str) -> list[Incident]:
        return [
            Incident.model_validate(_clean(d))
            for d in IncidentRepository.collection.find(
                {"group_id": group_id}
            )
        ]

    @staticmethod
    def list_by_pilgrim(pilgrim_id: str) -> list[Incident]:
        return [
            Incident.model_validate(_clean(d))
            for d in IncidentRepository.collection.find(
                {"pilgrim_id": pilgrim_id}
            )
        ]


def seed_demo_data() -> dict[str, str]:
    if not AgencyRepository.get(DEMO_AGENCY_ID):
        AgencyRepository.create(
            Agency(
                id=DEMO_AGENCY_ID,
                name="Smart Hajj Demo Agency",
                country="Morocco",
                contact_email="operations@smarthajj.demo",
                contact_phone="+212600000000",
            )
        )

    if not GuideRepository.get(DEMO_GUIDE_ID):
        GuideRepository.create(
            Guide(
                id=DEMO_GUIDE_ID,
                agency_id=DEMO_AGENCY_ID,
                name="Ahmed El Amrani",
                phone_number="+212611111111",
                email="ahmed@smarthajj.demo",
            )
        )

    if not GroupRepository.get(DEMO_GROUP_ID):
        GroupRepository.create(
            Group(
                id=DEMO_GROUP_ID,
                agency_id=DEMO_AGENCY_ID,
                name="Group A",
                guide_id=DEMO_GUIDE_ID,
                description="Primary Smart Hajj Guardian demo group.",
            )
        )

    if not PilgrimRepository.get(DEMO_PILGRIM_ID):
        existing_phone = PilgrimRepository.get_by_phone(
            DEMO_PHONE_NUMBER
        )
        if existing_phone is None:
            PilgrimRepository.create(
                Pilgrim(
                    id=DEMO_PILGRIM_ID,
                    group_id=DEMO_GROUP_ID,
                    agency_id=DEMO_AGENCY_ID,
                    name="Demo Pilgrim",
                    phone_number=DEMO_PHONE_NUMBER,
                    nationality="Moroccan",
                )
            )

    return {
        "agency_id": DEMO_AGENCY_ID,
        "guide_id": DEMO_GUIDE_ID,
        "group_id": DEMO_GROUP_ID,
        "pilgrim_id": DEMO_PILGRIM_ID,
        "phone_number": DEMO_PHONE_NUMBER,
    }


def clear_all_repositories():
    db.agencies.delete_many({})
    db.guides.delete_many({})
    db.groups.delete_many({})
    db.pilgrims.delete_many({})
    db.safe_zones.delete_many({})
    db.incidents.delete_many({})
