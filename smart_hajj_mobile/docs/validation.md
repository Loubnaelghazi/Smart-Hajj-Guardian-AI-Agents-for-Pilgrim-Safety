# Validation record

## Bilingual update · 2026-09-10

- `flutter analyze`: no issues.
- `flutter test`: 36 tests passed, including translation coverage, saved language, all seven routes in English/Arabic at 360×800, RTL direction, and SOS cancellation without a POST.
- `flutter build apk --debug`: passed, including native bilingual location notifications. Artifact: `build/app/outputs/flutter-apk/app-debug.apk`.
- Docker backend observation tests: 9 passed. Briefing tests: 4 passed.
- Dashboard tracking/filter tests: 6 passed. Vite production build passed.
- Live read-only smoke checks returned HTTP 200 for `/health`, demo agency tracking, demo pilgrim, and demo group.
- These checks do not establish real carrier integration or minimized-device GPS reliability. The latest APK has not been installed and visually checked on a device; earlier ADB operations timed out. The in-app browser was unavailable for dashboard visual checks. No live SOS or paid network action was triggered in this update.
- App language is persisted and updates UI, layout direction, and active Android sharing notifications. Names and agency-authored content remain as supplied. No AI provider key is needed for bilingual UI or the evidence-summary fallback.

## Earlier validation · 2026-09-06

Environment: Flutter 3.47.2, Dart 3.13.2, Android emulator `emulator-5554` (Android 17 / API 37), existing Docker backend `smart-hajj-backend` 0.7.0, MongoDB health true.

## Automated checks

- Dependency resolution: `flutter pub get` completed successfully.
- Static analysis: `flutter analyze` completed with no issues.
- Unit/widget suite: **26 passing tests** for JSON models, risk/action display, null safe zones, HTTP failures, unknown values, incident privacy filtering, alert deduplication, preservation of data during failed refresh, duplicate SOS taps, session logout, polling lifecycle, SOS confirmation and small-screen text scaling.
- Android debug APK build completed successfully.
- Real-device integration test passed: demo onboarding, Home/Group/Safety/Profile navigation, deliberate SOS confirmation, actual Guardian response, current-pilgrim active incident lookup and agency overview verification.

The integration test initially exposed a Flutter assertion around expansion tiles painted inside decorated containers. Shared cards were changed to Material surfaces; the full integration test then passed.

## Live backend outcome

The requested demo SOS created/updated this backend incident:

```text
60715a25-3d07-488a-8f6a-be371f29b2da
type: SOS
status: OPEN
pilgrim_id: demo-pilgrim-001
risk_score: 100
risk_level: CRITICAL
```

The same SOS was found in `/api/incidents/active` and `/api/agencies/demo-agency-001/overview`, the feeds available to the existing agency command center. The backend also returned `qosStatus: REQUESTED`, duration 60 seconds. This verifies the backend request response, not guaranteed ongoing network priority or guide notification delivery.

No existing incidents were resolved, no guide/agency messages were sent, no safe zone was created, and no backend source was changed. The existing critical incident remains separate from the SOS.

## Current configuration and limits of verification

The real demo pilgrim is named `test hajj`, in `Group A`, guided by `Ahmed El Amrani`. The app displays these actual records. The group currently has **no safe zone**. The nonfatal absence was exercised in the app and model/repository tests. A full normal analysis against a real configured group zone requires the agency to configure that zone; the app deliberately does not substitute the backend's simulator circle for a group zone.

Backend-down behavior is covered by injected transport failures, without interrupting the running shared backend. Risk transitions and unknown values are covered by model/widget tests; no fictional safety fixtures are shipped as runtime app data. Arabic, iOS, real push notifications and background monitoring were not validated or claimed.

The installed app uses `http://10.0.2.2:8000`; emulator login and SOS verify that it reaches the Windows-published Docker port. The Android toolchain still reports missing SDK command-line tools/license-status diagnostics in `flutter doctor`, but the installed SDK/Gradle setup successfully built and ran the app.
