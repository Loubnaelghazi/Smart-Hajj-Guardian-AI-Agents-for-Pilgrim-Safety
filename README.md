# Smart Hajj Guardian

Pilgrim assistance prototype with a FastAPI backend, LangGraph orchestration, Nokia network API integration and an English/Arabic React agency dashboard. The English/Arabic Flutter mobile application is included in `smart_hajj_mobile/`.

## Hackathon demo

- **Agency dashboard:** https://smart-hajj-dashboard.onrender.com/
- **Backend API documentation:** https://smart-hajj-guardian-ai-agents-for.onrender.com/docs
- **Mobile source and setup:** [Flutter README](smart_hajj_mobile/README.md)

The demo starts with an already registered agency, group, guide and pilgrim. The hosted backend may take time to respond after inactivity on the free Render instance. Use synthetic demo data only.

## How the safety workflow works

1. The agency selects a meeting point on the map and saves the group safety-zone radius.
2. With permission and foreground tracking enabled, the mobile sends GPS observations, accuracy and timestamps to the backend and triggers analysis.
3. LangGraph coordinates six logical agents: **Supervisor, Telecom, Risk, Navigation, Emergency and Memory**. They collect network context, assess risk, return guidance, escalate critical cases and record outcomes.
4. A critical risk assessment can create a **CRITICAL_RISK** incident without an SOS tap. Leaving the zone alone does not necessarily reach the critical threshold.
5. **Manual SOS** is a separate flow that creates an SOS incident and requests Quality on Demand. A requested QoD session does not prove that network priority was activated.
6. Agency staff follow incidents in the dashboard, acknowledge them and mark them resolved.

The recorded automatic example combined outside-zone verification (+30), severe separation (+40) and medium network congestion (+20): a score of 90, above the critical threshold of 80. These are prototype rules, not clinically or operationally validated safety thresholds.

Nokia integrations cover **Location Verification, Device Reachability, Congestion Insights, Quality on Demand and Consent Info**. Not every API is invoked on every analysis; Consent Info is a separate check, and cached network signals may be reused.

## Architecture and hosting

```text
Flutter mobile / React agency dashboard
                  | HTTPS
       FastAPI + LangGraph agents
          |                  |
       MongoDB          Nokia network APIs
```

Local development runs the backend and MongoDB in Docker containers. The hosted demo runs the containerized backend on Render, the React dashboard as a static site, and the database on MongoDB Atlas. Database and Nokia credentials stay on the backend.

## Features

- Agency, group, guide, pilgrim and meeting-area management.
- Live tracking with guide/group filters, GPS freshness and accuracy checks.
- Automatic critical-risk and manual SOS incidents with acknowledgment and resolution.
- English/Arabic dashboard with right-to-left layout.
- Optional bilingual incident briefing; no LLM key is required for the fallback.

## Run the backend and database

Requirements: Docker Desktop with Docker Compose. On Windows, enable integration with Debian if running these commands in WSL.

Run in this repository root:

```bash
cp .env.example .env
# Set NOKIA_API_KEY in .env for network API access.
docker compose up --build -d
```

API documentation: http://localhost:8000/docs

Compose configures MongoDB automatically. Its bundled database credentials are for local development only. The root .env currently supplies NOKIA_API_KEY to Compose; other custom backend settings must also be passed through the backend environment configuration.

## Run the agency dashboard

Use Node.js 22.12 or later.

```bash
cd client
npm ci
npm run dev
```

Open http://localhost:5173. The development server proxies API requests to localhost:8000. The default agency ID is demo-agency-001; it must exist in the database. Set VITE_AGENCY_ID in client/.env when using another agency. Set VITE_API_BASE_URL to the public backend URL for a hosted dashboard; configure backend CORS for that dashboard origin.

## Checks

```bash
cd client
npm run build
node --test src/services/tracking.test.js
```

## Suggested evaluation walkthrough

1. Open the dashboard Overview and inspect the demo group and assigned guide.
2. Inspect the meeting zone on the map, then open the mobile with a registered demo pilgrim phone.
3. Switch between English and Arabic and enable location sharing.
4. Use emulator locations inside and outside the zone; inspect the dashboard tracking filters and returned risk evidence. An outside location alone may produce a warning rather than a critical incident, depending on the other signals.
5. Confirm a manual SOS and follow its acknowledgement and resolution in the dashboard.

## Prototype scope

The video uses an Android emulator, simulated GPS and Nokia simulator signals. Its automatic critical incident is presented as recorded evidence. Field validation remains pending. Automatic mobile analysis requires active foreground tracking; this prototype does not guarantee continuous monitoring when the app is closed. Phone lookup in the demo is not identity verification.


Nokia API access requires appropriate credentials and a supported device or simulator. Network congestion is not crowd density. GPS sharing requires user permission. Risk and navigation decisions are rule-based; scores are not validated probabilities of harm. Incident status does not prove rescue.

Before public deployment, configure HTTPS, authenticated access, agency isolation, production credentials and persistent storage. Do not expose MongoDB or Mongo Express publicly. Never commit .env files or API keys.


## Flutter mobile application

The Android/iOS Flutter source is in [`smart_hajj_mobile`](smart_hajj_mobile/README.md), alongside `backend` (FastAPI) and `client` (React dashboard).

With Flutter and an Android emulator or USB debugging device installed:

```sh
cd smart_hajj_mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=https://smart-hajj-guardian-ai-agents-for.onrender.com
```

Use a pilgrim phone registered in the hosted dashboard. The mobile app calls the hosted backend; do not put MongoDB or Nokia credentials in Flutter. See the mobile README for local Docker alternatives and demo limitations.

## Author

**Loubna El Ghazi**  AI & Cybersecurity PhD student, Abdelmalek Essaadi University, C3S Lab, Morocco.

[LinkedIn](https://www.linkedin.com/in/loubna-el-ghazi/)
