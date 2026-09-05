from datetime import datetime, timezone
from typing import Any


def _parse_datetime(value: str | None) -> datetime | None:
    if not value:
        return None

    try:
        cleaned = value.replace("Z", "+00:00")
        dt = datetime.fromisoformat(cleaned)

        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=timezone.utc)

        return dt

    except ValueError:
        return None


def _age_seconds(value: str | None) -> float | None:
    dt = _parse_datetime(value)

    if dt is None:
        return None

    now = datetime.now(timezone.utc)

    return max(
        0.0,
        (now - dt).total_seconds()
    )


def calculate_confidence(
    state: dict[str, Any],
) -> dict[str, Any]:

    score = 100

    signals_expected = 3
    signals_available = 0

    missing_signals: list[str] = []
    stale_signals: list[str] = []
    evidence: list[str] = []

    # =====================================================
    # LOCATION VERIFICATION
    # =====================================================

    location_verification = state.get(
        "location_verification"
    )

    if location_verification:

        signals_available += 1

        evidence.append(
            "location_verification_available"
        )

        last_location_time = (
            location_verification.get(
                "lastLocationTime"
            )
        )

        age = _age_seconds(
            last_location_time
        )

        if age is None:

            score -= 10

            stale_signals.append(
                "location_verification_timestamp_unknown"
            )

        elif age > 300:

            score -= 25

            stale_signals.append(
                "location_verification"
            )

        elif age > 120:

            score -= 10

            stale_signals.append(
                "location_verification"
            )

    else:

        score -= 35

        missing_signals.append(
            "location_verification"
        )

    # =====================================================
    # REACHABILITY
    # =====================================================

    reachability = state.get(
        "reachability"
    )

    if reachability:

        signals_available += 1

        evidence.append(
            "reachability_available"
        )

        last_status_time = (
            reachability.get(
                "lastStatusTime"
            )
        )

        age = _age_seconds(
            last_status_time
        )

        if age is None:

            score -= 10

            stale_signals.append(
                "reachability_timestamp_unknown"
            )

        elif age > 300:

            score -= 20

            stale_signals.append(
                "reachability"
            )

        elif age > 120:

            score -= 10

            stale_signals.append(
                "reachability"
            )

    else:

        score -= 25

        missing_signals.append(
            "reachability"
        )

    # =====================================================
    # CONGESTION
    # =====================================================

    congestion = state.get(
        "congestion"
    )

    telecom_sources = state.get(
        "telecom_sources",
        {},
    )

    congestion_source = (
        telecom_sources
        .get("congestion", {})
    )

    if congestion:

        signals_available += 1

        evidence.append(
            "congestion_available"
        )

        source = congestion_source.get(
            "source"
        )

        cache_age = congestion_source.get(
            "cache_age_seconds"
        )

        if source == "cache":

            evidence.append(
                "congestion_from_cache"
            )

            if cache_age is not None:

                if cache_age > 300:

                    score -= 25

                    stale_signals.append(
                        "congestion"
                    )

                elif cache_age > 120:

                    score -= 10

                    stale_signals.append(
                        "congestion"
                    )

            else:

                score -= 5

    else:

        score -= 20

        missing_signals.append(
            "congestion"
        )

    # =====================================================
    # TELECOM ERRORS
    # =====================================================

    telecom_errors = state.get(
        "telecom_errors",
        [],
    )

    if telecom_errors:

        penalty = min(
            len(telecom_errors) * 10,
            30,
        )

        score -= penalty

        evidence.append(
            "telecom_errors_present"
        )

    # =====================================================
    # NORMALIZE SCORE
    # =====================================================

    score = max(
        0,
        min(100, score)
    )

    # =====================================================
    # CONFIDENCE LEVEL
    # =====================================================

    if score >= 80:

        level = "HIGH"

    elif score >= 50:

        level = "MEDIUM"

    else:

        level = "LOW"

    return {
        "score": score,
        "level": level,
        "signals_available":
            signals_available,
        "signals_expected":
            signals_expected,
        "missing_signals":
            missing_signals,
        "stale_signals":
            stale_signals,
        "evidence":
            evidence,
    }