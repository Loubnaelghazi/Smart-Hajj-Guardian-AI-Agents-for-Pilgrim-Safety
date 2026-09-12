# Smart Hajj Guardian · Pilgrim mobile app

A Flutter group-safety companion connected to the **existing FastAPI backend**, alongside the React agency command center. Home, Group, Safety, Profile, safe-zone details, return-to-group guidance, and emergency status use real backend entities and decisions. No local risk scoring, direct Nokia calls, or fabricated authentication.

## Connect to the hosted backend (phone or Android emulator)

The app now uses `https://smart-hajj-guardian-ai-agents-for.onrender.com` by default.
You do not need local Docker, a MongoDB connection string, or a Nokia API key on the phone.
Internet access is required. A GitHub push is not required to test locally.

1. Open this `smart_hajj_mobile` folder in VS Code.
2. Start an Android emulator from Android Studio, or connect an Android phone with USB debugging enabled.
3. Select the device in VS Code and launch **Hajj Guardian - Render (backend heberge)** using F5.
4. Enter a phone number already registered in the hosted agency dashboard (demo: `+99999991000`).
5. Allow location access when testing GPS. On an emulator, set its simulated position using Extended controls > Location.

Alternatively, from this folder:

```powershell
flutter pub get
flutter devices
flutter run --dart-define=API_BASE_URL=https://smart-hajj-guardian-ai-agents-for.onrender.com
```

If Render is waking up, open the backend `/health` URL, wait until it responds, then retry in the app.
Existing locally saved sessions may refer to your old database: use Profile > Leave demo session and join again.
Emulator GPS is simulated; use a physical phone to validate actual location collection.

## Run against a local backend (optional)

Backend recovery (2026-09-09): if `/health` closes the connection and Docker logs
say `Could not import module "backend.main"`, check the source mount. The
container was found with an empty `/app/backend` even though the source existed
in Debian. Run `powershell -File tooling/start-backend.ps1` from this project to
recreate only the backend from the correct WSL distribution. This preserves
MongoDB, but resets volatile safety snapshots; run a fresh safety check afterward.

Validated SDK: **Flutter 3.47.2 / Dart 3.13.2**. Install Android Studio, an Android SDK and emulator. On this computer Flutter is at `C:\Users\acer\Desktop\dev\flutter_windows_3.47.2-stable\flutter\bin`; add that directory to your terminal PATH if necessary.

```powershell
cd C:\Users\acer\Desktop\dev\smart_hajj_mobile
flutter doctor
flutter pub get
flutter emulators
flutter devices
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

Use `flutter emulators --launch <emulator-id>` if your emulator is not already running. The device ID may differ from `emulator-5554`.

The local Android emulator override is `http://10.0.2.2:8000`. Configuration is centralized in `lib/core/config/app_config.dart`; nothing secret belongs in Dart defines.

For a physical Android phone on the same Wi-Fi:

```powershell
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000
```

Replace the address with your computer's LAN IP. Allow incoming TCP 8000 through the host firewall for your development network.

### Existing Docker backend

The inspected backend is version **0.7.0**, container **smart-hajj-backend**, exposing `8000:8000`. Its source is mounted at `/app/backend` from Debian:

```text
/home/Lubna/projects/ia/smart_hajj_guardian_tier1/smart_hajj_guardian/backend
```

The additive phone lookup in `backend_patch/routes/operations.py` has been applied to the existing backend. Existing routes remain compatible. Start the existing Docker Compose project as usual, then verify:

```powershell
docker ps
curl.exe http://localhost:8000/health
docker logs --tail 50 smart-hajj-backend
```

Expected health includes `status: ok` and `mongodb: true`. Open `http://10.0.2.2:8000/health` in the Android emulator's browser to verify its connection. `localhost` **inside Android refers to Android**, not the Windows host. Docker/WSL must publish port 8000 to Windows; Uvicorn must bind to `0.0.0.0` inside its container.

HTTP is permitted **only by the Android debug manifest**. Release Android builds use the platform's default cleartext restrictions and require an HTTPS API URL. The scaffold's release signing is still a debug key; configure your own release signing before distributing a release build.

### Demo session

Default identity:

| Setting | Default |
|---|---|
| `PILGRIM_ID` | `demo-pilgrim-001` |
| `GROUP_ID` | `demo-group-001` |
| `AGENCY_ID` | `demo-agency-001` |
| `DEMO_PHONE` | `+99999991000` |

Enter **any registered pilgrim's phone** and choose **Join my Hajj group**. The app calls `POST /api/pilgrims/lookup` and uses the matched record's pilgrim ID, group, agency and phone. `PILGRIM_ID` no longer selects the login identity; `DEMO_PHONE` only supplies the initially displayed phone. Enter the phone exactly as registered, including its country code; leading/trailing whitespace is trimmed. Unknown numbers receive a clear error. This remains a locally persisted **demo session, not phone verification or authentication**. Profile → Leave demo session clears it.

## Architecture

```text
lib/
  app.dart                         go_router, session redirects, theme/locales
  core/config/                     public application configuration
  core/network/                    Dio, timeouts, normalized errors
  core/storage/                    SharedPreferences demo session
  core/theme/                      semantic risk colors and Material 3 theme
  l10n/                            English catalog/localization delegate
  models/domain.dart               nullable, tolerant backend models
  repositories/                    operations, Guardian and incident contracts
  providers/                       Riverpod session and aggregated dashboard
  services/                        foreground polling and alert deduplication
  screens/                         onboarding and pilgrim feature screens
  widgets/                         safety card, SOS confirmation, shared UI
test/                              model, repository and widget tests
integration_test/                  emulator test against the real backend
docs/backend-contract.md           inspected contracts and product boundaries
tooling/desktop_scaffolds/          original unused desktop starter projects
```

Widgets → Riverpod controller → repositories → centralized Dio client → FastAPI → existing Guardian workflow → Nokia/CAMARA. Widgets never perform raw HTTP. Dependencies: Riverpod 3, Dio 5, go_router 18, SharedPreferences 2, url_launcher 6, Flutter localization SDK. Versions are locked in `pubspec.lock`.

The Android, iOS and web scaffold remains. The original Windows/Linux/macOS starter folders were preserved under `tooling/desktop_scaffolds` because this is a mobile product; their active presence caused unnecessary Windows plugin symlink requirements. Restore them to the project root if you later add desktop support, and enable Windows Developer Mode for symlinks. No global Flutter or Windows settings were changed.

### Refresh, alerts and lifecycle

- One foreground timer polls active incidents every **5 seconds**, scoped strictly by `pilgrim_id` before display.
- Read-only Guardian snapshots (`GET /api/pilgrims`) refresh every **10 seconds** on relevant screens. Only the current phone's state is retained.
- Trip details refresh every **30 seconds**, or with pull-to-refresh. Home pull-to-refresh also runs analysis when there is a valid group safe zone.
- **Check safety now** invokes the actual analyze POST. Polling does not repeatedly run telecom analysis or create incidents.
- Requests are guarded against duplicate taps. Poll results started before an analysis/SOS cannot overwrite its outcome. Pausing the app stops the clock; foregrounding resumes it. Disposing the shell stops the timer.
- Failed refreshes preserve previously loaded data. Safety older than 120 seconds is labeled outdated. Persisted storage holds session identity only; profile/safety data remains in memory and is fetched again after restart.
- HTTP 429 pauses background polling for 30 seconds. SOS POSTs are never automatically retried. An unconfirmed timeout warns that the request may have arrived and lets the user refresh status before retrying.
- New relevant incidents and acknowledgment changes generate in-app snackbars and persistent alert cards. This is **not FCM/APNs push** and does not monitor in the background.

## Demo flow and truthful status

1. Join with the existing demo pilgrim. Actual names and group details are displayed, even if they differ from pitch examples.
2. In the existing agency dashboard, configure the group's safe-zone coordinates and radius. Run a safety check on mobile. The phone supplies that real zone to Guardian; it does not invent a distance or location.
3. Use your existing backend/simulator scenario controls to change network evidence or distance, then check again. MEDIUM/HIGH transitions show backend risk and recommendations. The inspected backend deliberately creates incidents only for **CRITICAL** and **SOS**, so MEDIUM/HIGH does not generate an agency incident with this version.
4. Tap SOS, then **Send SOS now**. The app displays Guardian's response and incident reference. The same incident is visible through existing React incident polling and agency overview.
5. A guide/agency acknowledgment in React is reflected by mobile polling. Mobile has no acknowledge/resolve controls.

**Missing safe zone:** a normal, nonfatal empty state. This backend otherwise falls back to a Nokia simulator circle (not the group's zone). To avoid misrepresenting that result, ordinary mobile analysis requires a configured valid zone. SOS stays available without one; its backend default area never establishes an “inside group zone” claim in the UI.

**Guide delivery:** this backend records an incident but has no confirmed guide-notification delivery field. Mobile therefore says “recorded in the agency command center / awaiting acknowledgment,” not “guide notified.” Actual `ACKNOWLEDGED` status is shown separately. No notification service was invented.

**QoD:** requested/active-at-last-response appears only if the backend reports it. Its duration/expiry is respected when available. Provider failures are not shown as network-priority success.

**Risk and confidence:** independent backend values, never “AI accuracy.” The read-only state endpoint omits confidence. A new snapshot therefore shows confidence unavailable until a full analysis supplies it, instead of carrying forward an unrelated confidence score.

## Validation

```powershell
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

Debug APK: `build/app/outputs/flutter-apk/app-debug.apk`.

Real emulator navigation test (backend must be running):

```powershell
flutter test integration_test/app_test.dart -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

To additionally send a **real demo SOS**, invoke:

```powershell
flutter test integration_test/app_test.dart -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:8000 --dart-define=RUN_LIVE_SOS=true
```

That test deliberately creates/updates an SOS incident and may request 60 seconds of network priority through the existing backend. It verifies the incident in both the mobile incident feed and agency overview. It does not resolve incidents or change safe zones. Use the React dashboard for the normal incident lifecycle.

## Prototype limits

- English and Arabic are available throughout the mobile UI with a saved language switch and right-to-left Arabic layout. Registered names and agency-provided content retain their original language. Android location-sharing notifications follow the selected language.
- Optional GPS monitoring uploads timestamped phone observations and connection type; the backend computes meeting-point distance. Android also includes opt-in foreground-service sharing while minimized, with an ongoing notification and Stop action. Minimized-device behavior still requires end-to-end verification. See [phone monitoring setup and validation](docs/phone-monitoring.md). Maps open externally; guide calls open the dialer. Push messaging remains unimplemented.
- No offline SOS queue or automatic retry, since the backend exposes no idempotency-key contract. Confirm uncertain requests through incident refresh or contact the guide.
- Backend operations are unauthenticated in the inspected prototype, and list endpoints contain broader data than a pilgrim needs. Client filtering is not server authorization. Real deployment requires authenticated, server-scoped endpoints and HTTPS.
- Android is the primary validated target. iOS requires macOS/Xcode and an HTTPS backend; web requires an explicitly permitted FastAPI CORS origin (the existing backend permits localhost ports used by its React dashboard).
- The backend's Nokia simulator inputs are not evidence of real-world Hajj coverage or location accuracy. The app displays returned data and uncertainty without relabeling it as verified real-world safety.
