from typing import Literal, Optional

from pydantic import BaseModel, Field


class PhoneRequest(BaseModel):
    phone_number: str = Field(
        ...,
        examples=["+99999991000"],
    )


class LocationRequest(PhoneRequest):
    max_age: int = Field(
        default=600,
        ge=0,
        le=3600,
    )


# =========================================================
# LOCATION VERIFICATION
# =========================================================

class CircleArea(BaseModel):
    latitude: float
    longitude: float

    radius: int = Field(
        ...,
        gt=0,
    )


def default_safe_area():
    """
    Nokia documented TRUE simulator example.
    """
    return CircleArea(
        latitude=47.44178899529922,
        longitude=19.160422047462603,
        radius=50000,
    )


class LocationVerificationRequest(
    PhoneRequest
):
    area: CircleArea = Field(
        default_factory=default_safe_area
    )

    max_age: int = Field(
        default=120,
        ge=0,
        le=3600,
    )


# =========================================================
# CONSENT
# =========================================================

class ConsentStatusRequest(
    PhoneRequest
):
    scopes: list[str] = Field(
        default_factory=lambda: [
            "location-verification:verify"
        ]
    )

    purpose: str = (
        "dpv:FraudPreventionAndDetection"
    )

    request_capture_url: bool = False


# =========================================================
# NUMBER VERIFICATION
# =========================================================

class NumberVerificationRequest(
    PhoneRequest
):
    pass


# =========================================================
# QOD
# =========================================================

class IPv4Address(BaseModel):
    public_address: str = "233.252.0.2"

    private_address: str = "192.0.2.25"

    public_port: int = Field(
        default=80,
        ge=1,
        le=65535,
    )


class QoDCreateRequest(
    PhoneRequest
):
    ipv4: IPv4Address = Field(
        default_factory=IPv4Address
    )

    application_server_ipv4: str = (
        "8.8.8.8"
    )

    qos_profile: str = (
        "DOWNLINK_M_UPLINK_L"
    )

    duration: int = Field(
        default=60,
        ge=1,
    )


class QoDExtendRequest(BaseModel):
    requested_additional_duration: int = Field(
        default=60,
        ge=1,
    )


# =========================================================
# CONGESTION
# =========================================================

class CongestionRequest(
    PhoneRequest
):
    subscription_expire_time: str = (
        "2045-04-12T14:09:33+05:00"
    )


# =========================================================
# GUARDIAN
# =========================================================

class GuardianAnalyzeRequest(
    PhoneRequest
):
    distance_from_group_m: Optional[
        float
    ] = Field(
        default=None,
        ge=0,
    )

    safe_area: CircleArea = Field(
        default_factory=default_safe_area
    )

    max_location_age: int = Field(
        default=120,
        ge=0,
        le=3600,
    )


class SOSRequest(
    PhoneRequest
):
    distance_from_group_m: Optional[
        float
    ] = Field(
        default=None,
        ge=0,
    )

    safe_area: CircleArea = Field(
        default_factory=default_safe_area
    )


class RiskResult(BaseModel):
    score: int

    level: Literal[
        "LOW",
        "MEDIUM",
        "HIGH",
        "CRITICAL",
    ]

    reasons: list[str]

    recommended_actions: list[str]