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


class MemoryAgent:

    def __init__(
        self,
        max_events_per_pilgrim: int = 20,
    ):

        self.max_events_per_pilgrim = (
            max_events_per_pilgrim
        )

        self._memory: dict[
            str,
            list[dict[str, Any]]
        ] = {}


    def remember(
        self,
        phone_number: str,
        event_type: str,
        payload: dict[str, Any],
    ) -> dict[str, Any]:

        event = {

            "timestamp":
                utc_now(),

            "type":
                event_type,

            "payload":
                payload,
        }


        if (
            phone_number
            not in
            self._memory
        ):

            self._memory[
                phone_number
            ] = []


        self._memory[
            phone_number
        ].insert(
            0,
            event,
        )


        del self._memory[
            phone_number
        ][
            self.max_events_per_pilgrim:
        ]


        return event


    def history(
        self,
        phone_number: str,
    ) -> list[dict[str, Any]]:

        return list(
            self._memory.get(
                phone_number,
                [],
            )
        )


    def recent_risk_levels(
        self,
        phone_number: str,
        limit: int = 5,
    ) -> list[str]:

        result = []


        for event in self.history(
            phone_number
        ):

            if (
                event.get(
                    "type"
                )
                ==
                "risk-analysis"
            ):

                level = (
                    event
                    .get(
                        "payload",
                        {},
                    )
                    .get(
                        "risk",
                        {},
                    )
                    .get(
                        "level"
                    )
                )


                if level:

                    result.append(
                        level
                    )


                if (
                    len(
                        result
                    )
                    >=
                    limit
                ):

                    break


        return result


    def summary(
        self,
        phone_number: str,
    ) -> dict[str, Any]:

        history = self.history(
            phone_number
        )


        return {

            "event_count":
                len(
                    history
                ),

            "recent_risk_levels":
                self.recent_risk_levels(
                    phone_number
                ),

            "recent_events":
                history[
                    :5
                ],
        }


    def clear(
        self,
    ):

        self._memory.clear()