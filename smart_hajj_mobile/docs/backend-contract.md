# Inspected backend contract

Source inspected directly in `smart-hajj-backend:/app/backend` on 2026-09-06: `main.py`, `models.py`, `domain_models.py`, `routes/operations.py`, `guardian_graph.py`, `incident_service.py`, `navigation_agent.py`, `state_store.py`, `confidence_engine.py`. FastAPI OpenAPI reports version 0.7.0. The phone-lookup addition dated 2026-09-09 is described below; existing endpoints are preserved.

## Requests

`POST /api/guardian/analyze` and `POST /api/guardian/sos` accept:

```json
{
  "phone_number": "+99999991000",
  "safe_area": {"latitude": 21.4, "longitude": 39.8, "radius": 250}
}
```

Coordinates above illustrate the schema only. Mobile uses coordinates fetched from the group's actual SafeZone, mapping `radius_m` to `radius`. `distance_from_group_m` is optional and never invented by mobile. Analyze additionally accepts `max_location_age` (default 120). SOS resolves pilgrim/group/agency/guide from the registered phone through existing repositories.

Without `safe_area`, backend uses its simulator default. Ordinary mobile checks require a configured zone; SOS can omit the area and does not present that fallback as the pilgrim's group zone.

## Guardian response shape

```text
phone_number
risk: { score, level, ... }
confidence: { score, level, missing_signals, stale_signals, ... }
navigation: { primary_action, guidance, distance_from_group_m, actions, ... }
emergency: { triggered, triggered_at?, qod_requested?, qod?, errors? }
incident: Incident | null
telecom_errors: []
telecom_sources: { signal: { source, cache_age_seconds?, ... } }
pilgrim_state: {
  phone_number, updated_at, geofence_state, distance_from_group_m,
  reachability, congestion: { data: [...] }, telecom_sources, ...
}
```

Risk levels: LOW/MEDIUM/HIGH/CRITICAL. Unknown levels remain unknown. Navigation can also return `AVOID_CONGESTED_ZONE` and `MOVE_TO_SAFE_CHECKPOINT`, beyond the three actions in the initial product brief. These receive readable guidance.

Only explicit SOS invokes QoD. Automatic critical evaluation enters emergency processing but reserves QoD for SOS. The backend marks `qod_requested` true only after the provider call returns successfully. QoD error details are not exposed verbatim to users.

## Reads used by mobile

| Endpoint | Shape / purpose |
|---|---|
| `/health` | `status`, `mongodb`, version |
| `/api/pilgrims/{id}` | Pilgrim domain entity |
| `/api/groups/{id}` | `{group, guide, safe_zone, pilgrims_count}`; parser also accepts plain group |
| `/api/guides/{id}` | Guide fallback if not included in group response |
| `/api/agencies/{id}` | Agency display name |
| `/api/groups/{id}/safe-zone` | `{safe_zone: object or null}`; parser also accepts plain zone and nonfatal 404 |
| `/api/incidents/active` | Array, filtered by exact current `pilgrim_id` and OPEN/ACKNOWLEDGED |
| `/api/pilgrims` | `{count, pilgrims: [state...]}`; filtered by exact phone; no confidence field |

Group-level incidents are intentionally not displayed without an explicit backend applicability contract. Unknown incident statuses are not asserted to be active. There is no mobile incident mutation route usage.

## Important capability boundaries

- Added on 2026-09-09: `POST /api/pilgrims/lookup` accepts a `phone_number` JSON field and returns the registered Pilgrim (404 when absent, 422 for invalid input). Onboarding uses that matching identity. This does not authenticate or verify phone ownership. See `backend_patch/README.md` for the complete backend replacement file.
- `IncidentService` deduplicates active incidents by pilgrim and type; it only creates/updates CRITICAL_RISK and SOS. MEDIUM/HIGH separation does not create an incident.
- No guide-notification delivery receipt exists. `navigation.actions` are recommendations, not evidence of delivery.
- `GET /api/pilgrims` contains volatile in-memory safety snapshots; restarting the backend can empty it. MongoDB incidents remain separate. Mobile does not equate no snapshot with LOW risk.
- Health connectivity is separate from device reachability and network signal confidence.
