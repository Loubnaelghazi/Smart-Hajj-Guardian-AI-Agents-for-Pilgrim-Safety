from dataclasses import dataclass
from time import monotonic
from typing import Any


@dataclass
class CacheEntry:
    value: Any
    created_at: float


class TelecomCache:

    def __init__(self):
        self._data: dict[
            str,
            CacheEntry
        ] = {}


    def set(
        self,
        key: str,
        value: Any,
    ):

        self._data[key] = CacheEntry(
            value=value,
            created_at=monotonic(),
        )


    def get(
        self,
        key: str,
        ttl_seconds: int,
    ):
        entry = self._data.get(
            key
        )

        if not entry:
            return None


        age = (
            monotonic()
            -
            entry.created_at
        )


        if age <= ttl_seconds:

            return {
                "value":
                    entry.value,

                "age_seconds":
                    round(
                        age,
                        2,
                    ),

                "fresh":
                    True,
            }


        return None


    def get_stale(
        self,
        key: str,
    ):
        entry = self._data.get(
            key
        )

        if not entry:
            return None


        age = (
            monotonic()
            -
            entry.created_at
        )


        return {
            "value":
                entry.value,

            "age_seconds":
                round(
                    age,
                    2,
                ),

            "fresh":
                False,
        }


    def clear(
        self
    ):

        self._data.clear()


    def count(
        self
    ):

        return len(
            self._data
        )