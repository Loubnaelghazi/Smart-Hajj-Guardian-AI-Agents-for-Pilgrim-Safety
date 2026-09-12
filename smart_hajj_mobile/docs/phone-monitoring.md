# Foreground phone monitoring

Tap **Start** in the phone safety monitoring card and grant location access. The app requests a fresh GPS fix every 30 seconds while visible, sends coordinates, accuracy, measurement time, mock-location flag and connection type to `POST /api/mobile/observations`, then requests the existing Guardian analysis. Stop, logout and backgrounding prevent further uploads; an already submitted request may finish. Resume restarts an enabled session. No background tracking or automatic SOS is implemented.

FastAPI resolves the registered phone's group and meeting point from MongoDB, calculates great-circle distance, and reports inside/outside/uncertain using GPS accuracy. Fixes older than 120 seconds or over 15 seconds in the future are rejected. Accuracy over 100 metres is displayed but excluded from separation scoring. Guardian uses the conservative distance minus accuracy, preserving its existing risk rules. Latest observations are stored in `mobile_observations`, one record per phone, without a movement history. An accepted observation can inform manual checks for up to 120 seconds after Stop; stale data clears the distance input. Meeting-point changes are recalculated at the next check.

Phone GPS, including an explicit mock flag where the OS provides one, is separate from Nokia verification. Wi-Fi/mobile connectivity does not prove internet access or crowd congestion. A server receipt confirms only that upload. Existing congestion may still use the configured simulator device. Distance is to a fixed meeting point, not the guide's live position. Maps open externally at the uploaded position.

## Device demo

1. Start the Docker backend and register the pilgrim through the agency workflow; configure their group's actual meeting point.
2. Install the debug APK. For a physical USB-connected Android phone, run `adb reverse tcp:8000 tcp:8000` and build with `--dart-define=API_BASE_URL=http://127.0.0.1:8000`. The default APK uses the Android emulator address `10.0.2.2`.
3. Sign in with that exact registered phone; tap Start and allow location while using the app.
4. Confirm the GPS accuracy, receipt time, distance and zone state. Walk outside the meeting-point radius and wait for a new measurement. Confirm the resulting backend safety check.
5. Background the app, reopen it, turn location off, disconnect the backend, then Stop. Verify the status reflects unavailable/paused/stopped monitoring.

This remains the existing hackathon identity model: phone lookup is not OTP authentication. The endpoint inherits that limitation. Android is the validated build target; iOS requires signing and device validation. No physical walk test is claimed by automated tests.

## Implementation references

[Geolocator](https://pub.dev/packages/geolocator) provides OS location and permission APIs. [Connectivity Plus](https://pub.dev/packages/connectivity_plus) reports connection type, not guaranteed internet access.

Backend deployment files: `backend_patch/main.py` and `backend_patch/mobile_observations.py`, copied to `/app/backend/` in `smart-hajj-backend`. `backend_patch/test_mobile_observations.py` covers distance, uncertainty, mock labeling and invalid timestamps/coordinates.
