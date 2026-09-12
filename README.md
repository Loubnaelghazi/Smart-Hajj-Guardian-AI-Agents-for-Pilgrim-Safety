# Smart Hajj Guardian

Pilgrim assistance prototype with a FastAPI backend, LangGraph orchestration, Nokia network API integration and an English/Arabic React agency dashboard. The Flutter mobile application is maintained separately.

## Features

- Agency, group, guide, pilgrim and meeting-area management.
- Live tracking with guide/group filters, GPS freshness and accuracy checks.
- SOS incidents with acknowledgment and resolution.
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

## Prototype scope

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
