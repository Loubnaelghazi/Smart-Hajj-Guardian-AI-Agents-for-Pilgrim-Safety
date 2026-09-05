from typing import Any

from .confidence_engine import calculate_confidence


# =========================================================
# HELPERS
# =========================================================

def _get_congestion_level(
    congestion: dict | None,
) -> str:

    if not congestion:
        return "UNKNOWN"

    data = congestion.get("data", [])

    if not data:
        return "UNKNOWN"

    latest = data[0]

    return str(
        latest.get(
            "congestionLevel",
            "UNKNOWN",
        )
    ).upper()


def _get_verification_result(
    location_verification: dict | None,
) -> str:

    if not location_verification:
        return "UNKNOWN"

    return str(
        location_verification.get(
            "verificationResult",
            "UNKNOWN",
        )
    ).upper()


# =========================================================
# RECOMMENDED ACTIONS
# =========================================================

def _recommended_actions(
    level: str,
) -> list[str]:

    if level == "LOW":

        return [
            "Continue monitoring.",
        ]

    if level == "MEDIUM":

        return [
            "Warn the pilgrim.",
            "Increase monitoring frequency.",
        ]

    if level == "HIGH":

        return [
            "Alert the pilgrim and assigned guide.",
            "Guide pilgrim toward their group.",
            "Avoid high-congestion areas.",
        ]

    return [
        "Escalate to command center.",
        "Prepare emergency response.",
        "Maintain reliable network communication.",
    ]


# =========================================================
# RISK ENGINE
# =========================================================

def calculate_risk(
    state: dict[str, Any],
) -> dict[str, Any]:

    score = 0

    reasons: list[str] = []
    evidence: list[str] = []

    # =====================================================
    # EXPLICIT SOS
    # =====================================================

    sos_triggered = bool(
        state.get("sos_triggered")
        or state.get("sos")
        or state.get("manual_sos")
    )

    if sos_triggered:

        risk = {
            "score": 100,
            "level": "CRITICAL",

            "reasons": [
                "Pilgrim manually triggered SOS."
            ],

            "recommended_actions": [
                "Escalate immediately to guide and command center.",
                "Check current network reachability.",
                "Request emergency Quality-on-Demand.",
            ],

            "evidence": [
                "manual_sos"
            ],
        }

        confidence = calculate_confidence(
            state
        )

        return {
            "risk": risk,
            "confidence": confidence,
        }

    # =====================================================
    # LOCATION VERIFICATION
    # =====================================================

    location_verification = state.get(
        "location_verification"
    )

    verification_result = (
        _get_verification_result(
            location_verification
        )
    )

    if verification_result == "FALSE":

        score += 30

        reasons.append(
            "Nokia Location Verification reports "
            "the pilgrim outside the configured "
            "safe area."
        )

        evidence.append(
            "outside_safe_zone"
        )

    elif verification_result == "TRUE":

        reasons.append(
            "Nokia Location Verification reports "
            "the pilgrim inside the configured "
            "safe area."
        )

        evidence.append(
            "inside_safe_zone"
        )

    else:

        evidence.append(
            "location_verification_unknown"
        )

    # =====================================================
    # DISTANCE FROM GROUP
    # =====================================================

    distance = state.get(
        "distance_from_group_m"
    )

    if distance is not None:

        try:
            distance = float(distance)

            # Keeps the validated behavior:
            # 300 / 450 m -> +25
            # 800 m       -> +40

            if distance >= 700:

                score += 40

                reasons.append(
                    f"Pilgrim is {int(distance)} m "
                    "from their group."
                )

                evidence.append(
                    "severe_group_separation"
                )

            elif distance >= 300:

                score += 25

                reasons.append(
                    f"Pilgrim is {int(distance)} m "
                    "from their group."
                )

                evidence.append(
                    "group_separation"
                )

            else:

                evidence.append(
                    "close_to_group"
                )

        except (
            TypeError,
            ValueError,
        ):

            evidence.append(
                "distance_invalid"
            )

    else:

        evidence.append(
            "distance_unknown"
        )

    # =====================================================
    # REACHABILITY
    # =====================================================

    reachability = state.get(
        "reachability"
    )

    if reachability:

        reachable = reachability.get(
            "reachable"
        )

        if reachable is True:

            reasons.append(
                "Device is reachable."
            )

            evidence.append(
                "device_reachable"
            )

        elif reachable is False:

            # Communication loss is treated
            # as an extra operational risk.
            score += 25

            reasons.append(
                "Device is not reachable."
            )

            evidence.append(
                "device_unreachable"
            )

        else:

            evidence.append(
                "reachability_unknown"
            )

    else:

        evidence.append(
            "reachability_missing"
        )

    # =====================================================
    # CONGESTION
    # =====================================================

    congestion = state.get(
        "congestion"
    )

    congestion_level = (
        _get_congestion_level(
            congestion
        )
    )

    if congestion_level == "HIGH":

        score += 35

        reasons.append(
            "Network congestion is High."
        )

        evidence.append(
            "high_congestion"
        )

    elif congestion_level == "MEDIUM":

        score += 20

        reasons.append(
            "Network congestion is Medium."
        )

        evidence.append(
            "medium_congestion"
        )

    elif congestion_level == "LOW":

        reasons.append(
            "Network congestion is Low."
        )

        evidence.append(
            "low_congestion"
        )

    else:

        evidence.append(
            "congestion_unknown"
        )

    # =====================================================
    # NORMALIZE SCORE
    # =====================================================

    score = max(
        0,
        min(100, int(score))
    )

    # =====================================================
    # RISK LEVEL
    # =====================================================

    if score >= 80:

        level = "CRITICAL"

    elif score >= 50:

        level = "HIGH"

    elif score >= 25:

        level = "MEDIUM"

    else:

        level = "LOW"

    # =====================================================
    # RESULT
    # =====================================================

    risk = {
        "score": score,
        "level": level,
        "reasons": reasons,
        "recommended_actions":
            _recommended_actions(level),
        "evidence": evidence,
    }

    confidence = calculate_confidence(
        state
    )

    return {
        "risk": risk,
        "confidence": confidence,
    }