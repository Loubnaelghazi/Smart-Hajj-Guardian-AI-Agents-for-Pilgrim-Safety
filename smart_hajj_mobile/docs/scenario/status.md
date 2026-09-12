# Scenario and backend recovery · 2026-09-09

Configured group `demo-group-001` with `Mina demo meeting point`, latitude
21.4133, longitude 39.8933, radius 250 m. Explicit simulator separation input:
450 m for `demo-pilgrim-001`. This is a test scenario, not measured GPS.

The two previous demo incidents were resolved through the existing API to start
the separation scenario without an older emergency overriding its presentation.
The original snapshot is in `before.json`.

On September 9, requests failed because `/app/backend` was empty inside the
container. Uvicorn logged `Could not import module "backend.main"`. The source
files still existed in Debian. Recreating only the backend through Docker Compose
inside Debian restored its bind mount. No backend source or MongoDB volumes were
changed. `tooling/start-backend.ps1` records the recovery procedure.

Verified after recovery:

- `/health`: status ok, MongoDB true, backend 0.7.0.
- Configured safe zone persisted across container recreation.
- Real `/api/guardian/analyze`: score 75, HIGH, confidence 100, outside zone,
  distance 450 m, medium congestion, RETURN_TO_GROUP.
- No new incident from HIGH risk, consistent with this backend's policy.

The emulator scenario test built and launched but failed in a test helper that
used `.first` on a finder before navigation/scrolling had built the target widget.
The helper now waits for navigation and passes the unsliced finder to scrolling.
This correction has not been rerun. A separate request to run static analysis and
the regression suite was declined. Full scenario validation is therefore pending;
the earlier 26-test result is historical, not a new test result from this run.

To continue the opt-in live scenario test:

```powershell
flutter test integration_test/scenario_test.dart -d emulator-5554 --dart-define=RUN_DEMO_SCENARIO=true
```

This test sends an actual demo SOS, verifies agency visibility, acknowledges and
resolves that incident, then checks the return-to-group state and logout/login.
