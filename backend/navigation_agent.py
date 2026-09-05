from typing import Any


def build_navigation_plan(
    pilgrim_state: dict[str, Any],
    risk: dict[str, Any],
) -> dict[str, Any]:

    level = risk.get(
        "level",
        "LOW",
    )

    geofence_state = pilgrim_state.get(
        "geofence_state",
        "unknown",
    )

    distance = pilgrim_state.get(
        "distance_from_group_m"
    )

    congestion = pilgrim_state.get(
        "congestion"
    )


    congestion_level = None


    if isinstance(
        congestion,
        dict,
    ):

        data = congestion.get(
            "data"
        )

        if isinstance(
            data,
            list,
        ):

            for item in data:

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

                    congestion_level = (
                        str(
                            item[
                                "congestionLevel"
                            ]
                        )
                        .upper()
                    )

                    break


    actions: list[str] = []

    primary_action = (
        "CONTINUE_MONITORING"
    )

    guidance = (
        "Continue with the group."
    )


    # =====================================================
    # CRITICAL
    # =====================================================

    if level == "CRITICAL":

        primary_action = (
            "WAIT_FOR_GUIDE"
        )

        guidance = (
            "Do not move into unfamiliar or "
            "high-risk areas. Stay in a safe "
            "position and wait for guide support."
        )

        actions.extend([
            "Notify assigned guide.",
            "Keep communication channel active.",
        ])


    # =====================================================
    # HIGH
    # =====================================================

    elif level == "HIGH":

        if (
            congestion_level
            ==
            "HIGH"
        ):

            primary_action = (
                "AVOID_CONGESTED_ZONE"
            )

            guidance = (
                "Avoid the congested area and "
                "move toward a safer route before "
                "returning to the group."
            )

            actions.extend([
                "Avoid current congestion zone.",
                "Return toward group using safer corridor.",
            ])


        elif (
            geofence_state
            ==
            "outside"
        ):

            primary_action = (
                "RETURN_TO_GROUP"
            )

            guidance = (
                "Return toward the assigned group "
                "or designated safe checkpoint."
            )

            actions.extend([
                "Move toward group.",
                "Notify guide of separation.",
            ])


        else:

            primary_action = (
                "MOVE_TO_SAFE_CHECKPOINT"
            )

            guidance = (
                "Move toward the nearest safe "
                "checkpoint and remain monitored."
            )


    # =====================================================
    # MEDIUM
    # =====================================================

    elif level == "MEDIUM":

        primary_action = (
            "RETURN_TO_GROUP"
        )

        guidance = (
            "Reduce separation from the group "
            "and continue monitoring."
        )

        actions.append(
            "Move closer to assigned group."
        )


    # =====================================================
    # LOW
    # =====================================================

    else:

        primary_action = (
            "CONTINUE_MONITORING"
        )

        guidance = (
            "No navigation intervention required."
        )


    return {

        "primary_action":
            primary_action,

        "guidance":
            guidance,

        "distance_from_group_m":
            distance,

        "congestion_level":
            congestion_level,

        "actions":
            actions,
    }