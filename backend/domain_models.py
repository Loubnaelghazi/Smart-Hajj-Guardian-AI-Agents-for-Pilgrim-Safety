from datetime import datetime, timezone
from enum import Enum
from typing import Optional

from pydantic import BaseModel, Field


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


# =========================================================
# ENUMS
# =========================================================

class IncidentStatus(str, Enum):
    OPEN = "OPEN"
    ACKNOWLEDGED = "ACKNOWLEDGED"
    RESOLVED = "RESOLVED"


class IncidentType(str, Enum):
    SEPARATION = "SEPARATION"
    CRITICAL_RISK = "CRITICAL_RISK"
    SOS = "SOS"


# =========================================================
# AGENCY
# =========================================================

class Agency(BaseModel):
    id: str

    name: str

    country: Optional[str] = None

    contact_email: Optional[str] = None

    contact_phone: Optional[str] = None

    created_at: datetime = Field(
        default_factory=utc_now
    )


# =========================================================
# GUIDE
# =========================================================

class Guide(BaseModel):
    id: str

    agency_id: str

    name: str

    phone_number: Optional[str] = None

    email: Optional[str] = None

    created_at: datetime = Field(
        default_factory=utc_now
    )


# =========================================================
# GROUP
# =========================================================

class Group(BaseModel):
    id: str

    agency_id: str

    name: str

    guide_id: Optional[str] = None

    description: Optional[str] = None

    created_at: datetime = Field(
        default_factory=utc_now
    )


# =========================================================
# PILGRIM
# =========================================================

class Pilgrim(BaseModel):
    id: str

    group_id: str

    agency_id: str

    name: str

    phone_number: str

    nationality: Optional[str] = None

    created_at: datetime = Field(
        default_factory=utc_now
    )


# =========================================================
# SAFE ZONE
# =========================================================

class SafeZone(BaseModel):
    id: str

    group_id: str

    name: str

    latitude: float

    longitude: float

    radius_m: int = 250

    created_at: datetime = Field(
        default_factory=utc_now
    )


# =========================================================
# INCIDENT
# =========================================================

class Incident(BaseModel):
    id: str

    type: IncidentType

    status: IncidentStatus = IncidentStatus.OPEN

    agency_id: str

    group_id: str

    pilgrim_id: str

    guide_id: Optional[str] = None

    risk_score: int

    risk_level: str

    confidence_score: Optional[int] = None

    confidence_level: Optional[str] = None

    navigation_action: Optional[str] = None

    evidence: list[str] = Field(
        default_factory=list
    )

    created_at: datetime = Field(
        default_factory=utc_now
    )

    acknowledged_at: Optional[datetime] = None

    resolved_at: Optional[datetime] = None