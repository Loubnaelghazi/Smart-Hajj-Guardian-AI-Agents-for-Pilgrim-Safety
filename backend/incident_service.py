from uuid import uuid4

from .domain_models import (
    Incident,
    IncidentStatus,
    IncidentType,
)
from .repositories import (
    IncidentRepository,
)


def _find_existing_active_incident(
    *,
    pilgrim_id: str,
    incident_type: IncidentType,
) -> Incident | None:
    incidents = (
        IncidentRepository
        .list_by_pilgrim(
            pilgrim_id
        )
    )

    for incident in incidents:
        if (
            incident.type == incident_type
            and
            incident.status
            != IncidentStatus.RESOLVED
        ):
            return incident

    return None


def create_incident_from_guardian_result(
    *,
    agency_id: str,
    group_id: str,
    pilgrim_id: str,
    guide_id: str | None,
    risk: dict,
    confidence: dict | None,
    navigation: dict | None,
    sos: bool = False,
) -> Incident | None:

    risk_level = str(
        risk.get(
            "level",
            "LOW",
        )
    ).upper()

    # Only CRITICAL risk or explicit SOS
    # should create/update an incident.
    if (
        not sos
        and
        risk_level != "CRITICAL"
    ):
        return None

    if sos:
        incident_type = (
            IncidentType.SOS
        )
    else:
        incident_type = (
            IncidentType.CRITICAL_RISK
        )

    confidence_score = None
    confidence_level = None

    if confidence:
        confidence_score = (
            confidence.get(
                "score"
            )
        )

        confidence_level = (
            confidence.get(
                "level"
            )
        )

    navigation_action = None

    if navigation:
        navigation_action = (
            navigation.get(
                "primary_action"
            )
        )

    evidence = list(
        risk.get(
            "evidence",
            [],
        )
    )

    # =====================================================
    # DEDUPLICATION
    # =====================================================

    existing = (
        _find_existing_active_incident(
            pilgrim_id=
                pilgrim_id,

            incident_type=
                incident_type,
        )
    )

    if existing:

        # Keep the same incident ID/status,
        # but refresh the latest Guardian data.
        existing.agency_id = (
            agency_id
        )

        existing.group_id = (
            group_id
        )

        existing.guide_id = (
            guide_id
        )

        existing.risk_score = int(
            risk.get(
                "score",
                0,
            )
        )

        existing.risk_level = (
            risk_level
        )

        existing.confidence_score = (
            confidence_score
        )

        existing.confidence_level = (
            confidence_level
        )

        existing.navigation_action = (
            navigation_action
        )

        existing.evidence = (
            evidence
        )

        return (
            IncidentRepository
            .update(
                existing
            )
        )

    # =====================================================
    # NEW INCIDENT
    # =====================================================

    incident = Incident(
        id=str(
            uuid4()
        ),

        type=
            incident_type,

        status=
            IncidentStatus.OPEN,

        agency_id=
            agency_id,

        group_id=
            group_id,

        pilgrim_id=
            pilgrim_id,

        guide_id=
            guide_id,

        risk_score=int(
            risk.get(
                "score",
                0,
            )
        ),

        risk_level=
            risk_level,

        confidence_score=
            confidence_score,

        confidence_level=
            confidence_level,

        navigation_action=
            navigation_action,

        evidence=
            evidence,
    )

    return (
        IncidentRepository
        .create(
            incident
        )
    )