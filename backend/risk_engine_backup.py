from typing import Any


def latest_congestion_level(
    congestion: Any,
):

    if not congestion:
        return None


    # Guardian stores:
    #
    # {
    #   "source_device": "...",
    #   "data": [...]
    # }

    if isinstance(
        congestion,
        dict,
    ) and "data" in congestion:

        congestion = (
            congestion[
                "data"
            ]
        )


    if isinstance(
        congestion,
        list,
    ):

        for item in congestion:

            if (
                isinstance(
                    item,
                    dict,
                )
                and
                item.get(
                    "congestionLevel"
                )
            ):

                return str(
                    item[
                        "congestionLevel"
                    ]
                ).lower()


    if isinstance(
        congestion,
        dict,
    ):

        value = congestion.get(
            "congestionLevel"
        )

        if value:

            return str(
                value
            ).lower()


    return None


def evaluate_risk(
    state: dict[str, Any],
    sos: bool = False,
):

    score = 0

    reasons = []

    actions = []


    # =====================================================
    # MANUAL SOS
    # =====================================================

    if sos:

        return {

            "score":
                100,

            "level":
                "CRITICAL",

            "reasons": [

                (
                    "Pilgrim manually "
                    "triggered SOS."
                )
            ],

            "recommended_actions": [

                (
                    "Escalate immediately "
                    "to guide and command center."
                ),

                (
                    "Check current network "
                    "reachability."
                ),

                (
                    "Request emergency "
                    "Quality-on-Demand."
                ),
            ],
        }


    # =====================================================
    # REAL LOCATION VERIFICATION
    # =====================================================

    geofence_state = state.get(
        "geofence_state"
    )


    if (
        geofence_state
        ==
        "outside"
    ):

        score += 30

        reasons.append(
            (
                "Nokia Location Verification "
                "reports the pilgrim outside "
                "the configured safe area."
            )
        )


    elif (
        geofence_state
        ==
        "inside"
    ):

        reasons.append(
            (
                "Nokia Location Verification "
                "reports the pilgrim inside "
                "the configured safe area."
            )
        )


    else:

        score += 5

        reasons.append(
            (
                "Safe-area location could "
                "not be confirmed."
            )
        )


    # =====================================================
    # GROUP SEPARATION DISTANCE
    # =====================================================

    distance = state.get(
        "distance_from_group_m"
    )


    if isinstance(
        distance,
        (int, float),
    ):

        if distance >= 700:

            score += 40

            reasons.append(
                (
                    f"Pilgrim is "
                    f"{distance:.0f} m "
                    "from their group."
                )
            )


        elif distance >= 300:

            score += 25

            reasons.append(
                (
                    f"Pilgrim is "
                    f"{distance:.0f} m "
                    "from their group."
                )
            )


        elif distance >= 100:

            score += 10

            reasons.append(
                (
                    f"Pilgrim is "
                    f"{distance:.0f} m "
                    "from their group."
                )
            )


    # =====================================================
    # REACHABILITY
    # =====================================================

    reachability = (
        state.get(
            "reachability"
        )
        or
        {}
    )


    reachable = reachability.get(
        "reachable"
    )


    if reachable is False:

        score += 25

        reasons.append(
            "Device is unreachable."
        )


    elif reachable is True:

        reasons.append(
            "Device is reachable."
        )


    # =====================================================
    # CONGESTION
    # =====================================================

    congestion_level = (
        latest_congestion_level(
            state.get(
                "congestion"
            )
        )
    )


    if (
        congestion_level
        ==
        "high"
    ):

        score += 35

        reasons.append(
            (
                "Network congestion "
                "is High."
            )
        )


    elif (
        congestion_level
        ==
        "medium"
    ):

        score += 20

        reasons.append(
            (
                "Network congestion "
                "is Medium."
            )
        )


    elif (
        congestion_level
        ==
        "low"
    ):

        reasons.append(
            (
                "Network congestion "
                "is Low."
            )
        )


    score = min(
        score,
        100,
    )


    # =====================================================
    # CLASSIFICATION
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
    # ACTIONS
    # =====================================================

    if level == "LOW":

        actions.append(
            "Continue monitoring."
        )


    elif level == "MEDIUM":

        actions.extend([

            (
                "Warn the pilgrim."
            ),

            (
                "Increase monitoring "
                "frequency."
            ),
        ])


    elif level == "HIGH":

        actions.extend([

            (
                "Alert the pilgrim "
                "and assigned guide."
            ),

            (
                "Guide pilgrim toward "
                "their group."
            ),

            (
                "Avoid high-congestion "
                "areas."
            ),
        ])


    else:

        actions.extend([

            (
                "Escalate to command center."
            ),

            (
                "Prepare emergency response."
            ),

            (
                "Maintain reliable "
                "network communication."
            ),
        ])


    return {

        "score":
            score,

        "level":
            level,

        "reasons":
            reasons,

        "recommended_actions":
            actions,
    }