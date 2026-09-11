from datetime import datetime, timezone
from uuid import uuid4

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field

from ..domain_models import (
    Agency,
    Guide,
    Group,
    IncidentStatus,
    Pilgrim,
    SafeZone,
)
from ..repositories import (
    AgencyRepository,
    GroupRepository,
    GuideRepository,
    IncidentRepository,
    PilgrimRepository,
    SafeZoneRepository,
)


router = APIRouter(
    prefix="/api",
    tags=["operations"],
)


# =========================================================
# REQUEST MODELS
# =========================================================

class CreateAgencyRequest(BaseModel):
    name: str
    country: str | None = None
    contact_email: str | None = None
    contact_phone: str | None = None


class UpdateAgencyRequest(BaseModel):
    name: str | None = None
    country: str | None = None
    contact_email: str | None = None
    contact_phone: str | None = None


class CreateGuideRequest(BaseModel):
    agency_id: str
    name: str
    phone_number: str | None = None
    email: str | None = None


class UpdateGuideRequest(BaseModel):
    name: str | None = None
    phone_number: str | None = None
    email: str | None = None


class CreateGroupRequest(BaseModel):
    agency_id: str
    name: str
    guide_id: str | None = None
    description: str | None = None


class UpdateGroupRequest(BaseModel):
    name: str | None = None
    guide_id: str | None = None
    description: str | None = None


class CreatePilgrimRequest(BaseModel):
    name: str
    phone_number: str
    nationality: str | None = None


class LookupPilgrimRequest(BaseModel):
    phone_number: str = Field(min_length=1, max_length=64)


class UpdatePilgrimRequest(BaseModel):
    name: str | None = None
    phone_number: str | None = None
    nationality: str | None = None
    group_id: str | None = None


class CreateSafeZoneRequest(BaseModel):
    name: str
    latitude: float
    longitude: float
    radius_m: int = 250


class UpdateSafeZoneRequest(BaseModel):
    name: str | None = None
    latitude: float | None = None
    longitude: float | None = None
    radius_m: int | None = None


def _patch_model(model, request_model):
    updates = request_model.model_dump(exclude_unset=True)
    return model.model_copy(update=updates)


# =========================================================
# AGENCY CRUD
# =========================================================

@router.post("/agencies")
async def create_agency(request: CreateAgencyRequest):
    agency = Agency(
        id=str(uuid4()),
        name=request.name,
        country=request.country,
        contact_email=request.contact_email,
        contact_phone=request.contact_phone,
    )
    AgencyRepository.create(agency)
    return agency


@router.get("/agencies/{agency_id}")
async def get_agency(agency_id: str):
    agency = AgencyRepository.get(agency_id)
    if not agency:
        raise HTTPException(404, "Agency not found.")
    return agency


@router.patch("/agencies/{agency_id}")
async def update_agency(
    agency_id: str,
    request: UpdateAgencyRequest,
):
    agency = AgencyRepository.get(agency_id)
    if not agency:
        raise HTTPException(404, "Agency not found.")

    agency = _patch_model(agency, request)
    AgencyRepository.update(agency)
    return agency


@router.delete("/agencies/{agency_id}")
async def delete_agency(agency_id: str):
    agency = AgencyRepository.get(agency_id)
    if not agency:
        raise HTTPException(404, "Agency not found.")

    # Protect referential integrity in this prototype.
    if GroupRepository.list_by_agency(agency_id):
        raise HTTPException(
            409,
            "Delete the agency groups before deleting the agency.",
        )
    if GuideRepository.list_by_agency(agency_id):
        raise HTTPException(
            409,
            "Delete the agency guides before deleting the agency.",
        )
    if PilgrimRepository.list_by_agency(agency_id):
        raise HTTPException(
            409,
            "Delete the agency pilgrims before deleting the agency.",
        )

    AgencyRepository.delete(agency_id)
    return {"deleted": True, "id": agency_id}


# =========================================================
# GUIDE CRUD
# =========================================================

@router.post("/guides")
async def create_guide(request: CreateGuideRequest):
    agency = AgencyRepository.get(request.agency_id)
    if not agency:
        raise HTTPException(404, "Agency not found.")

    guide = Guide(
        id=str(uuid4()),
        agency_id=request.agency_id,
        name=request.name,
        phone_number=request.phone_number,
        email=request.email,
    )
    GuideRepository.create(guide)
    return guide


@router.get("/guides/{guide_id}")
async def get_guide(guide_id: str):
    guide = GuideRepository.get(guide_id)
    if not guide:
        raise HTTPException(404, "Guide not found.")
    return guide


@router.get("/agencies/{agency_id}/guides")
async def list_agency_guides(agency_id: str):
    if not AgencyRepository.get(agency_id):
        raise HTTPException(404, "Agency not found.")
    return GuideRepository.list_by_agency(agency_id)


@router.patch("/guides/{guide_id}")
async def update_guide(
    guide_id: str,
    request: UpdateGuideRequest,
):
    guide = GuideRepository.get(guide_id)
    if not guide:
        raise HTTPException(404, "Guide not found.")

    guide = _patch_model(guide, request)
    GuideRepository.update(guide)
    return guide


@router.delete("/guides/{guide_id}")
async def delete_guide(guide_id: str):
    guide = GuideRepository.get(guide_id)
    if not guide:
        raise HTTPException(404, "Guide not found.")

    assigned_groups = [
        group
        for group in GroupRepository.list_by_agency(guide.agency_id)
        if group.guide_id == guide_id
    ]
    if assigned_groups:
        raise HTTPException(
            409,
            "This guide is assigned to one or more groups. "
            "Reassign or clear those groups first.",
        )

    GuideRepository.delete(guide_id)
    return {"deleted": True, "id": guide_id}


# =========================================================
# GROUP CRUD
# =========================================================

@router.post("/groups")
async def create_group(request: CreateGroupRequest):
    agency = AgencyRepository.get(request.agency_id)
    if not agency:
        raise HTTPException(404, "Agency not found.")

    if request.guide_id:
        guide = GuideRepository.get(request.guide_id)
        if not guide:
            raise HTTPException(404, "Guide not found.")
        if guide.agency_id != request.agency_id:
            raise HTTPException(
                400,
                "Guide does not belong to this agency.",
            )

    group = Group(
        id=str(uuid4()),
        agency_id=request.agency_id,
        name=request.name,
        guide_id=request.guide_id,
        description=request.description,
    )
    GroupRepository.create(group)
    return group


@router.get("/groups/{group_id}")
async def get_group(group_id: str):
    group = GroupRepository.get(group_id)
    if not group:
        raise HTTPException(404, "Group not found.")

    return {
        "group": group,
        "guide": (
            GuideRepository.get(group.guide_id)
            if group.guide_id
            else None
        ),
        "safe_zone": SafeZoneRepository.get_by_group(group_id),
        "pilgrims_count": len(
            PilgrimRepository.list_by_group(group_id)
        ),
    }


@router.get("/agencies/{agency_id}/groups")
async def list_agency_groups(agency_id: str):
    if not AgencyRepository.get(agency_id):
        raise HTTPException(404, "Agency not found.")
    return GroupRepository.list_by_agency(agency_id)


@router.patch("/groups/{group_id}")
async def update_group(
    group_id: str,
    request: UpdateGroupRequest,
):
    group = GroupRepository.get(group_id)
    if not group:
        raise HTTPException(404, "Group not found.")

    updates = request.model_dump(exclude_unset=True)

    if "guide_id" in updates and updates["guide_id"]:
        guide = GuideRepository.get(updates["guide_id"])
        if not guide:
            raise HTTPException(404, "Guide not found.")
        if guide.agency_id != group.agency_id:
            raise HTTPException(
                400,
                "Guide does not belong to this agency.",
            )

    group = group.model_copy(update=updates)
    GroupRepository.update(group)
    return group


@router.delete("/groups/{group_id}")
async def delete_group(group_id: str):
    group = GroupRepository.get(group_id)
    if not group:
        raise HTTPException(404, "Group not found.")

    pilgrims = PilgrimRepository.list_by_group(group_id)
    if pilgrims:
        raise HTTPException(
            409,
            "Delete or move the pilgrims in this group first.",
        )

    active_incidents = [
        incident
        for incident in IncidentRepository.list_by_group(group_id)
        if incident.status != IncidentStatus.RESOLVED
    ]
    if active_incidents:
        raise HTTPException(
            409,
            "Resolve this group's active incidents before deleting it.",
        )

    SafeZoneRepository.delete_by_group(group_id)
    GroupRepository.delete(group_id)
    return {"deleted": True, "id": group_id}


# =========================================================
# PILGRIM CRUD
# =========================================================

@router.post("/groups/{group_id}/pilgrims")
async def create_pilgrim(
    group_id: str,
    request: CreatePilgrimRequest,
):
    group = GroupRepository.get(group_id)
    if not group:
        raise HTTPException(404, "Group not found.")

    existing = PilgrimRepository.get_by_phone(
        request.phone_number
    )
    if existing:
        raise HTTPException(
            409,
            "A pilgrim with this phone number already exists.",
        )

    pilgrim = Pilgrim(
        id=str(uuid4()),
        group_id=group.id,
        agency_id=group.agency_id,
        name=request.name,
        phone_number=request.phone_number,
        nationality=request.nationality,
    )
    PilgrimRepository.create(pilgrim)
    return pilgrim


@router.get("/groups/{group_id}/pilgrims")
async def list_group_pilgrims(group_id: str):
    if not GroupRepository.get(group_id):
        raise HTTPException(404, "Group not found.")
    return PilgrimRepository.list_by_group(group_id)


@router.get("/pilgrims/{pilgrim_id}")
async def get_pilgrim(pilgrim_id: str):
    pilgrim = PilgrimRepository.get(pilgrim_id)
    if not pilgrim:
        raise HTTPException(404, "Pilgrim not found.")
    return pilgrim


@router.post("/pilgrims/lookup", response_model=Pilgrim)
async def lookup_pilgrim(request: LookupPilgrimRequest):
    """Demo identification only; this does not verify phone ownership."""
    phone = request.phone_number.strip()
    if not phone:
        raise HTTPException(422, "Phone number is required.")
    pilgrim = PilgrimRepository.get_by_phone(phone)
    if not pilgrim:
        raise HTTPException(404, "No pilgrim is registered with this phone number.")
    return pilgrim


@router.patch("/pilgrims/{pilgrim_id}")
async def update_pilgrim(
    pilgrim_id: str,
    request: UpdatePilgrimRequest,
):
    pilgrim = PilgrimRepository.get(pilgrim_id)
    if not pilgrim:
        raise HTTPException(404, "Pilgrim not found.")

    updates = request.model_dump(exclude_unset=True)

    if "phone_number" in updates:
        existing = PilgrimRepository.get_by_phone(
            updates["phone_number"]
        )
        if existing and existing.id != pilgrim_id:
            raise HTTPException(
                409,
                "A pilgrim with this phone number already exists.",
            )

    if "group_id" in updates:
        new_group = GroupRepository.get(updates["group_id"])
        if not new_group:
            raise HTTPException(404, "Target group not found.")
        if new_group.agency_id != pilgrim.agency_id:
            raise HTTPException(
                400,
                "Pilgrim cannot be moved to another agency.",
            )

    pilgrim = pilgrim.model_copy(update=updates)
    PilgrimRepository.update(pilgrim)
    return pilgrim


@router.delete("/pilgrims/{pilgrim_id}")
async def delete_pilgrim(pilgrim_id: str):
    pilgrim = PilgrimRepository.get(pilgrim_id)
    if not pilgrim:
        raise HTTPException(404, "Pilgrim not found.")

    active_incidents = [
        incident
        for incident in IncidentRepository.list_by_pilgrim(
            pilgrim_id
        )
        if incident.status != IncidentStatus.RESOLVED
    ]
    if active_incidents:
        raise HTTPException(
            409,
            "Resolve this pilgrim's active incidents before deleting.",
        )

    PilgrimRepository.delete(pilgrim_id)
    return {"deleted": True, "id": pilgrim_id}


# =========================================================
# SAFE ZONE CRUD
# =========================================================

@router.post("/groups/{group_id}/safe-zone")
async def create_safe_zone(
    group_id: str,
    request: CreateSafeZoneRequest,
):
    if not GroupRepository.get(group_id):
        raise HTTPException(404, "Group not found.")

    existing = SafeZoneRepository.get_by_group(group_id)
    if existing:
        raise HTTPException(
            409,
            "This group already has a safe zone. Use PATCH.",
        )

    safe_zone = SafeZone(
        id=str(uuid4()),
        group_id=group_id,
        name=request.name,
        latitude=request.latitude,
        longitude=request.longitude,
        radius_m=request.radius_m,
    )
    SafeZoneRepository.create(safe_zone)
    return safe_zone


@router.get("/groups/{group_id}/safe-zone")
async def get_safe_zone(group_id: str):
    group = GroupRepository.get(group_id)

    if not group:
        raise HTTPException(
            status_code=404,
            detail="Group not found.",
        )

    safe_zone = SafeZoneRepository.get_by_group(group_id)

    return {
        "safe_zone": safe_zone
    }

@router.patch("/groups/{group_id}/safe-zone")
async def update_safe_zone(
    group_id: str,
    request: UpdateSafeZoneRequest,
):
    safe_zone = SafeZoneRepository.get_by_group(group_id)
    if not safe_zone:
        raise HTTPException(404, "Safe zone not found.")

    safe_zone = _patch_model(safe_zone, request)
    SafeZoneRepository.update(safe_zone)
    return safe_zone


@router.delete("/groups/{group_id}/safe-zone")
async def delete_safe_zone(group_id: str):
    if not SafeZoneRepository.get_by_group(group_id):
        raise HTTPException(404, "Safe zone not found.")

    SafeZoneRepository.delete_by_group(group_id)
    return {"deleted": True, "group_id": group_id}


# =========================================================
# INCIDENT LIFECYCLE
# =========================================================

@router.get("/incidents/active")
async def list_active_incidents():
    return IncidentRepository.list_active()


@router.get("/incidents/{incident_id}")
async def get_incident(incident_id: str):
    incident = IncidentRepository.get(incident_id)
    if not incident:
        raise HTTPException(404, "Incident not found.")
    return incident


@router.patch("/incidents/{incident_id}/acknowledge")
async def acknowledge_incident(incident_id: str):
    incident = IncidentRepository.get(incident_id)
    if not incident:
        raise HTTPException(404, "Incident not found.")

    if incident.status == IncidentStatus.RESOLVED:
        raise HTTPException(
            400,
            "Resolved incident cannot be acknowledged.",
        )

    incident.status = IncidentStatus.ACKNOWLEDGED
    incident.acknowledged_at = datetime.now(timezone.utc)
    IncidentRepository.update(incident)
    return incident


@router.patch("/incidents/{incident_id}/resolve")
async def resolve_incident(incident_id: str):
    incident = IncidentRepository.get(incident_id)
    if not incident:
        raise HTTPException(404, "Incident not found.")

    incident.status = IncidentStatus.RESOLVED
    incident.resolved_at = datetime.now(timezone.utc)
    IncidentRepository.update(incident)
    return incident


# =========================================================
# AGENCY OVERVIEW
# =========================================================

@router.get("/agencies/{agency_id}/overview")
async def agency_overview(agency_id: str):
    agency = AgencyRepository.get(agency_id)
    if not agency:
        raise HTTPException(404, "Agency not found.")

    groups = GroupRepository.list_by_agency(agency_id)
    guides = GuideRepository.list_by_agency(agency_id)
    pilgrims = PilgrimRepository.list_by_agency(agency_id)
    incidents = IncidentRepository.list_by_agency(agency_id)

    active_incidents = [
        incident
        for incident in incidents
        if incident.status != IncidentStatus.RESOLVED
    ]

    critical_incidents = []
    for incident in active_incidents:
        risk_level = getattr(
            incident.risk_level,
            "value",
            incident.risk_level,
        )
        if str(risk_level).upper() == "CRITICAL":
            critical_incidents.append(incident)

    return {
        "agency": agency,
        "groups_count": len(groups),
        "guides_count": len(guides),
        "pilgrims_count": len(pilgrims),
        "active_incidents_count": len(active_incidents),
        "critical_incidents_count": len(critical_incidents),
        "summary": {
            "groups": len(groups),
            "guides": len(guides),
            "pilgrims": len(pilgrims),
            "active_incidents": len(active_incidents),
            "critical_incidents": len(critical_incidents),
        },
        "groups": groups,
        "guides": guides,
        "pilgrims": pilgrims,
        "active_incidents": active_incidents,
    }
