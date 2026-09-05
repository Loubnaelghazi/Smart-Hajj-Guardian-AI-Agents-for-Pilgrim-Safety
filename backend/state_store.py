from copy import deepcopy

from datetime import (
    datetime,
    timezone,
)

from typing import Any


def utc_now() -> str:

    return (
        datetime.now(
            timezone.utc
        ).isoformat()
    )


class PilgrimStateStore:

    def __init__(
        self
    ):

        self._states: dict[
            str,
            dict[str, Any]
        ] = {}


    def _base(
        self,
        phone_number: str,
    ):

        return {

            "phone_number":
                phone_number,

            "updated_at":
                utc_now(),

            # Derived from real Nokia
            # Location Verification.
            "geofence_state":
                "unknown",

            "location_verification":
                None,

            # Location Retrieval remains optional.
            "location":
                None,

            "distance_from_group_m":
                None,

            "reachability":
                None,

            "congestion":
                None,

            "risk":
                None,

            "last_sos":
                None,
            "navigation": None,
            "memory_summary": None,
            "qod_session":
                None,

            "telecom_sources":
                {},
        }


    def get(
        self,
        phone_number: str,
    ):

        if (
            phone_number
            not in
            self._states
        ):

            self._states[
                phone_number
            ] = self._base(
                phone_number
            )


        return deepcopy(
            self._states[
                phone_number
            ]
        )


    def update(
        self,
        phone_number: str,
        **changes,
    ):

        if (
            phone_number
            not in
            self._states
        ):

            self._states[
                phone_number
            ] = self._base(
                phone_number
            )


        state = self._states[
            phone_number
        ]


        state.update(
            changes
        )


        state[
            "updated_at"
        ] = utc_now()


        return deepcopy(
            state
        )


    def all(
        self
    ):

        return [

            deepcopy(
                value
            )

            for value
            in self._states.values()
        ]