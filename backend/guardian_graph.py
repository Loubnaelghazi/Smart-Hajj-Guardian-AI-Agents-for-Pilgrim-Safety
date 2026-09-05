from typing import (
    Any,
    TypedDict,
)

from langgraph.graph import (
    END,
    StateGraph,
)

from .config import (
    CONGESTION_CACHE_SECONDS,
    CONGESTION_DEVICE_PHONE,
    LOCATION_VERIFY_CACHE_SECONDS,
    QOD_APPLICATION_SERVER_IPV4,
    QOD_DURATION,
    QOD_PRIVATE_ADDRESS,
    QOD_PROFILE,
    QOD_PUBLIC_ADDRESS,
    QOD_PUBLIC_PORT,
    REACHABILITY_CACHE_SECONDS,
)

from .memory_agent import (
    MemoryAgent,
)

from .navigation_agent import (
    build_navigation_plan,
)

from .nokia_client import (
    NokiaAPIError,
    NokiaClient,
)

from .risk_engine import (
    calculate_risk,
)

from .state_store import (
    PilgrimStateStore,
    utc_now,
)

from .telecom_cache import (
    TelecomCache,
)

# =========================================================
# NEW: INCIDENT / AGENCY LAYER
# =========================================================

from .incident_service import (
    create_incident_from_guardian_result,
)

from .repositories import (
    GroupRepository,
    PilgrimRepository,
)


# =========================================================
# GRAPH STATE
# =========================================================

class GuardianGraphState(
    TypedDict,
    total=False,
):

    phone_number: str

    # =====================================================
    # NEW: ORGANIZATIONAL CONTEXT
    # =====================================================

    agency_id: str | None
    group_id: str | None
    pilgrim_id: str | None
    guide_id: str | None

    distance_from_group_m: float | None

    safe_area: dict[str, Any]

    max_location_age: int

    sos: bool

    pilgrim_state: dict[str, Any]

    telecom_errors: list[
        dict[str, Any]
    ]

    risk: dict[str, Any]

    confidence: dict[str, Any]

    navigation: dict[str, Any]

    emergency: dict[str, Any]

    # NEW
    incident: dict[str, Any] | None

    memory_summary: dict[str, Any]

    final: dict[str, Any]


# =========================================================
# GUARDIAN WORKFLOW
# =========================================================

class GuardianWorkflow:

    def __init__(
        self,
        nokia: NokiaClient,
        store: PilgrimStateStore,
        cache: TelecomCache,
        memory: MemoryAgent,
    ):

        self.nokia = nokia
        self.store = store
        self.cache = cache
        self.memory = memory

        self.graph = self._build()

    # =====================================================
    # BUILD GRAPH
    # =====================================================

    def _build(
        self
    ):

        graph = StateGraph(
            GuardianGraphState
        )

        graph.add_node(
            "collect_context",
            self.collect_context,
        )

        graph.add_node(
            "risk_agent",
            self.risk_agent,
        )

        graph.add_node(
            "navigation_agent",
            self.navigation_agent,
        )

        graph.add_node(
            "emergency_agent",
            self.emergency_agent,
        )

        # NEW
        graph.add_node(
            "incident_agent",
            self.incident_agent,
        )

        graph.add_node(
            "memory_agent",
            self.memory_agent,
        )

        graph.add_node(
            "finalize",
            self.finalize,
        )

        graph.set_entry_point(
            "collect_context"
        )

        graph.add_edge(
            "collect_context",
            "risk_agent",
        )

        # Risk always produces navigation guidance.
        graph.add_edge(
            "risk_agent",
            "navigation_agent",
        )

        graph.add_conditional_edges(
            "navigation_agent",
            self.route_after_navigation,
            {
                "emergency":
                    "emergency_agent",

                "normal":
                    "memory_agent",
            },
        )

        # UPDATED:
        # CRITICAL / SOS now goes:
        #
        # Emergency
        #   ↓
        # Incident
        #   ↓
        # Memory

        graph.add_edge(
            "emergency_agent",
            "incident_agent",
        )

        graph.add_edge(
            "incident_agent",
            "memory_agent",
        )

        graph.add_edge(
            "memory_agent",
            "finalize",
        )

        graph.add_edge(
            "finalize",
            END,
        )

        return graph.compile()

    # =====================================================
    # CONTEXT COLLECTION
    # =====================================================

    async def collect_context(
        self,
        state: GuardianGraphState,
    ):

        phone = state[
            "phone_number"
        ]

        errors = []

        sources = {}

        current = self.store.get(
            phone
        )

        # =================================================
        # DISTANCE
        # =================================================

        if (
            state.get(
                "distance_from_group_m"
            )
            is not None
        ):

            current = self.store.update(
                phone,

                distance_from_group_m=
                    state[
                        "distance_from_group_m"
                    ],
            )

        # =================================================
        # LOCATION VERIFICATION
        # =================================================

        area = state[
            "safe_area"
        ]

        location_key = (
            f"location-verify:"
            f"{phone}:"
            f"{area['latitude']}:"
            f"{area['longitude']}:"
            f"{area['radius']}"
        )

        cached_location = (
            self.cache.get(
                location_key,
                LOCATION_VERIFY_CACHE_SECONDS,
            )
        )

        verification = None

        if cached_location:

            verification = (
                cached_location[
                    "value"
                ]
            )

            sources[
                "location_verification"
            ] = {
                "source":
                    "cache",

                "cache_age_seconds":
                    cached_location[
                        "age_seconds"
                    ],
            }

        else:

            try:

                verification = (
                    await self.nokia
                    .verify_location(
                        phone_number=
                            phone,

                        latitude=
                            area[
                                "latitude"
                            ],

                        longitude=
                            area[
                                "longitude"
                            ],

                        radius=
                            area[
                                "radius"
                            ],

                        max_age=
                            state.get(
                                "max_location_age",
                                120,
                            ),
                    )
                )

                self.cache.set(
                    location_key,
                    verification,
                )

                sources[
                    "location_verification"
                ] = {
                    "source":
                        "live-nokia"
                }

            except NokiaAPIError as exc:

                stale = (
                    self.cache
                    .get_stale(
                        location_key
                    )
                )

                if stale:

                    verification = (
                        stale[
                            "value"
                        ]
                    )

                    sources[
                        "location_verification"
                    ] = {
                        "source":
                            "stale-cache",

                        "cache_age_seconds":
                            stale[
                                "age_seconds"
                            ],
                    }

                errors.append({
                    "service":
                        "location-verification",

                    "status":
                        exc.status_code,

                    "detail":
                        exc.detail,
                })

        # =================================================
        # INTERPRET LOCATION RESULT
        # =================================================

        if verification:

            result = str(
                verification.get(
                    "verificationResult",
                    "UNKNOWN",
                )
            ).upper()

            if result == "TRUE":

                geofence_state = (
                    "inside"
                )

            elif result == "FALSE":

                geofence_state = (
                    "outside"
                )

            else:

                geofence_state = (
                    "unknown"
                )

            current = self.store.update(
                phone,

                geofence_state=
                    geofence_state,

                location_verification=
                    verification,
            )

        # =================================================
        # REACHABILITY
        # =================================================

        reach_key = (
            f"reachability:"
            f"{phone}"
        )

        cached_reach = (
            self.cache.get(
                reach_key,
                REACHABILITY_CACHE_SECONDS,
            )
        )

        reachability = None

        if cached_reach:

            reachability = (
                cached_reach[
                    "value"
                ]
            )

            sources[
                "reachability"
            ] = {
                "source":
                    "cache",

                "cache_age_seconds":
                    cached_reach[
                        "age_seconds"
                    ],
            }

        else:

            try:

                reachability = (
                    await self.nokia
                    .retrieve_reachability(
                        phone
                    )
                )

                self.cache.set(
                    reach_key,
                    reachability,
                )

                sources[
                    "reachability"
                ] = {
                    "source":
                        "live-nokia"
                }

            except NokiaAPIError as exc:

                stale = (
                    self.cache
                    .get_stale(
                        reach_key
                    )
                )

                if stale:

                    reachability = (
                        stale[
                            "value"
                        ]
                    )

                    sources[
                        "reachability"
                    ] = {
                        "source":
                            "stale-cache",

                        "cache_age_seconds":
                            stale[
                                "age_seconds"
                            ],
                    }

                errors.append({
                    "service":
                        "device-reachability",

                    "status":
                        exc.status_code,

                    "detail":
                        exc.detail,
                })

        if reachability:

            current = self.store.update(
                phone,

                reachability=
                    reachability,
            )

        # =================================================
        # CONGESTION
        # =================================================

        congestion_phone = (
            CONGESTION_DEVICE_PHONE
        )

        congestion_key = (
            f"congestion:"
            f"{congestion_phone}"
        )

        cached_congestion = (
            self.cache.get(
                congestion_key,
                CONGESTION_CACHE_SECONDS,
            )
        )

        congestion_data = None

        if cached_congestion:

            congestion_data = (
                cached_congestion[
                    "value"
                ]
            )

            sources[
                "congestion"
            ] = {
                "source":
                    "cache",

                "cache_age_seconds":
                    cached_congestion[
                        "age_seconds"
                    ],

                "simulator_device":
                    congestion_phone,
            }

        # During SOS, avoid waiting for a fresh congestion
        # request if no cached value exists.
        elif not state.get(
            "sos",
            False,
        ):

            try:

                raw_congestion = (
                    await self.nokia
                    .query_congestion(
                        congestion_phone
                    )
                )

                congestion_data = {
                    "source_device":
                        congestion_phone,

                    "data":
                        raw_congestion,
                }

                self.cache.set(
                    congestion_key,
                    congestion_data,
                )

                sources[
                    "congestion"
                ] = {
                    "source":
                        "live-nokia",

                    "simulator_device":
                        congestion_phone,
                }

            except NokiaAPIError as exc:

                stale = (
                    self.cache
                    .get_stale(
                        congestion_key
                    )
                )

                if stale:

                    congestion_data = (
                        stale[
                            "value"
                        ]
                    )

                    sources[
                        "congestion"
                    ] = {
                        "source":
                            "stale-cache",

                        "cache_age_seconds":
                            stale[
                                "age_seconds"
                            ],

                        "simulator_device":
                            congestion_phone,
                    }

                errors.append({
                    "service":
                        "congestion-insights",

                    "status":
                        exc.status_code,

                    "detail":
                        exc.detail,
                })

        if congestion_data:

            current = self.store.update(
                phone,

                congestion=
                    congestion_data,
            )

        # =================================================
        # TELECOM SOURCE METADATA
        # =================================================

        current = self.store.update(
            phone,

            telecom_sources=
                sources,
        )

        return {
            "pilgrim_state":
                current,

            "telecom_errors":
                errors,
        }

    # =====================================================
    # RISK AGENT
    # =====================================================

    async def risk_agent(
        self,
        state: GuardianGraphState,
    ):

        risk_input = dict(
            state[
                "pilgrim_state"
            ]
        )

        risk_input[
            "telecom_errors"
        ] = state.get(
            "telecom_errors",
            [],
        )

        risk_input[
            "sos"
        ] = state.get(
            "sos",
            False,
        )

        risk_result = calculate_risk(
            risk_input
        )

        risk = risk_result[
            "risk"
        ]

        confidence = risk_result[
            "confidence"
        ]

        current = self.store.update(
            state[
                "phone_number"
            ],

            risk=
                risk,
        )

        return {
            "risk":
                risk,

            "confidence":
                confidence,

            "pilgrim_state":
                current,
        }

    # =====================================================
    # NAVIGATION AGENT
    # =====================================================

    async def navigation_agent(
        self,
        state: GuardianGraphState,
    ):

        navigation = (
            build_navigation_plan(
                state[
                    "pilgrim_state"
                ],

                state[
                    "risk"
                ],
            )
        )

        current = self.store.update(
            state[
                "phone_number"
            ],

            navigation=
                navigation,
        )

        return {
            "navigation":
                navigation,

            "pilgrim_state":
                current,
        }

    # =====================================================
    # ROUTING
    # =====================================================

    def route_after_navigation(
        self,
        state: GuardianGraphState,
    ):

        # Explicit SOS always enters emergency flow.

        if state.get(
            "sos",
            False,
        ):

            return (
                "emergency"
            )

        # Automatic CRITICAL risk also enters
        # emergency flow.

        if (
            state.get(
                "risk",
                {},
            ).get(
                "level"
            )
            ==
            "CRITICAL"
        ):

            return (
                "emergency"
            )

        return (
            "normal"
        )

    # =====================================================
    # EMERGENCY AGENT
    # =====================================================

    async def emergency_agent(
        self,
        state: GuardianGraphState,
    ):

        phone = state[
            "phone_number"
        ]

        emergency = {
            "triggered":
                True,

            "triggered_at":
                utc_now(),

            "qod_requested":
                False,

            "qod":
                None,

            "errors":
                [],
        }

        # =================================================
        # AUTOMATIC CRITICAL
        # =================================================

        if not state.get(
            "sos",
            False,
        ):

            emergency[
                "action"
            ] = (
                "Critical risk detected. "
                "Guide escalation required. "
                "QoD reserved for explicit SOS."
            )

            return {
                "emergency":
                    emergency
            }

        # =================================================
        # EXPLICIT SOS → QoD
        # =================================================

        try:

            qod = (
                await self.nokia
                .create_qod_session(
                    phone_number=
                        phone,

                    public_address=
                        QOD_PUBLIC_ADDRESS,

                    private_address=
                        QOD_PRIVATE_ADDRESS,

                    public_port=
                        QOD_PUBLIC_PORT,

                    application_server_ipv4=
                        QOD_APPLICATION_SERVER_IPV4,

                    qos_profile=
                        QOD_PROFILE,

                    duration=
                        QOD_DURATION,
                )
            )

            emergency[
                "qod_requested"
            ] = True

            emergency[
                "qod"
            ] = qod

            self.store.update(
                phone,

                qod_session=
                    qod,

                last_sos=
                    emergency[
                        "triggered_at"
                    ],
            )

        except NokiaAPIError as exc:

            emergency[
                "errors"
            ].append({
                "service":
                    "quality-on-demand",

                "status":
                    exc.status_code,

                "detail":
                    exc.detail,
            })

        return {
            "emergency":
                emergency
        }

    # =====================================================
    # NEW: INCIDENT AGENT
    # =====================================================

    async def incident_agent(
        self,
        state: GuardianGraphState,
    ):

        phone = state[
            "phone_number"
        ]

        agency_id = state.get(
            "agency_id"
        )

        group_id = state.get(
            "group_id"
        )

        pilgrim_id = state.get(
            "pilgrim_id"
        )

        guide_id = state.get(
            "guide_id"
        )

        # =================================================
        # RESOLVE PILGRIM BY PHONE
        # =================================================

        if not pilgrim_id:

            pilgrim = (
                PilgrimRepository
                .get_by_phone(
                    phone
                )
            )

            if pilgrim:

                pilgrim_id = (
                    pilgrim.id
                )

                group_id = (
                    group_id
                    or pilgrim.group_id
                )

                agency_id = (
                    agency_id
                    or pilgrim.agency_id
                )

        # =================================================
        # RESOLVE GUIDE / AGENCY FROM GROUP
        # =================================================

        if group_id:

            group = (
                GroupRepository.get(
                    group_id
                )
            )

            if group:

                if not guide_id:

                    guide_id = (
                        group.guide_id
                    )

                if not agency_id:

                    agency_id = (
                        group.agency_id
                    )

        # =================================================
        # BACKWARD COMPATIBILITY
        # =================================================
        #
        # Existing Guardian requests currently contain only
        # a phone number.
        #
        # Until that phone is registered as an agency
        # pilgrim, we do NOT break the workflow.

        if not all([
            agency_id,
            group_id,
            pilgrim_id,
        ]):

            return {
                "incident":
                    None
            }

        # =================================================
        # CREATE INCIDENT
        # =================================================

        incident = (
            create_incident_from_guardian_result(
                agency_id=
                    agency_id,

                group_id=
                    group_id,

                pilgrim_id=
                    pilgrim_id,

                guide_id=
                    guide_id,

                risk=
                    state.get(
                        "risk",
                        {},
                    ),

                confidence=
                    state.get(
                        "confidence"
                    ),

                navigation=
                    state.get(
                        "navigation"
                    ),

                sos=
                    state.get(
                        "sos",
                        False,
                    ),
            )
        )

        if incident is None:

            return {
                "incident":
                    None
            }

        return {
            "incident":
                incident.model_dump(
                    mode="json"
                )
        }

    # =====================================================
    # MEMORY AGENT
    # =====================================================

    async def memory_agent(
        self,
        state: GuardianGraphState,
    ):

        phone = state[
            "phone_number"
        ]

        event_payload = {
            "risk":
                state.get(
                    "risk"
                ),

            "confidence":
                state.get(
                    "confidence"
                ),

            "navigation":
                state.get(
                    "navigation"
                ),

            "emergency":
                state.get(
                    "emergency",
                    {
                        "triggered":
                            False
                    },
                ),

            # NEW
            "incident":
                state.get(
                    "incident"
                ),

            "telecom_errors":
                state.get(
                    "telecom_errors",
                    [],
                ),
        }

        self.memory.remember(
            phone,

            "risk-analysis",

            event_payload,
        )

        if state.get(
            "sos",
            False,
        ):

            self.memory.remember(
                phone,

                "sos",

                event_payload,
            )

        summary = self.memory.summary(
            phone
        )

        current = self.store.update(
            phone,

            memory_summary=
                summary,
        )

        return {
            "memory_summary":
                summary,

            "pilgrim_state":
                current,
        }

    # =====================================================
    # FINALIZE
    # =====================================================

    async def finalize(
        self,
        state: GuardianGraphState,
    ):

        pilgrim_state = self.store.get(
            state[
                "phone_number"
            ]
        )

        return {
            "final": {
                "phone_number":
                    state[
                        "phone_number"
                    ],

                "risk":
                    state.get(
                        "risk"
                    ),

                "confidence":
                    state.get(
                        "confidence"
                    ),

                "navigation":
                    state.get(
                        "navigation"
                    ),

                "emergency":
                    state.get(
                        "emergency",
                        {
                            "triggered":
                                False
                        },
                    ),

                # NEW
                "incident":
                    state.get(
                        "incident"
                    ),

                "memory":
                    state.get(
                        "memory_summary"
                    ),

                "telecom_errors":
                    state.get(
                        "telecom_errors",
                        [],
                    ),

                "telecom_sources":
                    (
                        pilgrim_state.get(
                            "telecom_sources",
                            {},
                        )
                        if pilgrim_state
                        else {}
                    ),

                "pilgrim_state":
                    pilgrim_state,
            }
        }

    # =====================================================
    # PUBLIC ANALYZE METHOD
    # =====================================================

    async def analyze(
        self,
        phone_number: str,
        distance_from_group_m: float | None,
        safe_area: dict,
        max_location_age: int = 120,
        sos: bool = False,

        # =================================================
        # NEW OPTIONAL ORGANIZATIONAL CONTEXT
        # =================================================

        agency_id: str | None = None,
        group_id: str | None = None,
        pilgrim_id: str | None = None,
        guide_id: str | None = None,
    ):

        result = (
            await self.graph
            .ainvoke({
                "phone_number":
                    phone_number,

                "distance_from_group_m":
                    distance_from_group_m,

                "safe_area":
                    safe_area,

                "max_location_age":
                    max_location_age,

                "sos":
                    sos,

                # NEW
                "agency_id":
                    agency_id,

                "group_id":
                    group_id,

                "pilgrim_id":
                    pilgrim_id,

                "guide_id":
                    guide_id,
            })
        )

        return result[
            "final"
        ]