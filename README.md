# Smart Hajj Guardian - Tier 1 Validation Prototype

FastAPI backend + minimal HTML console for validating the first Nokia Network as Code integrations before building the agent layer and mobile/dashboard UI.

## Tier 1 integrations

- Location Retrieval v0.2.0
- Geofencing v0.3.0
- Congestion Insights v1.0.0
- Device Reachability Status Retrieve v1.1.0

## Setup

```bash
python -m venv .venv
source .venv/bin/activate      # Windows: .venv\\Scripts\\activate
pip install -r requirements.txt
cp .env.example .env
```

Put your real Nokia/RapidAPI key in `.env`:

```env
NOKIA_API_KEY=your_key_here
NOKIA_API_HOST=network-as-code.nokia.rapidapi.com
NOKIA_BASE_URL=https://network-as-code.p-eu.apihub.nokia.io
PUBLIC_BASE_URL=http://localhost:8000
```

Run from the project root:

```bash
uvicorn backend.main:app --reload
```

Open http://127.0.0.1:8000

Interactive API docs: http://127.0.0.1:8000/docs

## Important webhook note

Nokia cannot call `localhost`. Geofencing and Congestion subscriptions need a publicly reachable HTTPS callback URL. During local validation, expose FastAPI using a tunnel and set `PUBLIC_BASE_URL` to that HTTPS URL.

The backend currently stores webhook events in memory at `GET /api/webhook-events` so the real Nokia payloads can be inspected before we model them permanently.

## Security

Never commit `.env` or the real API key. `.gitignore` already excludes `.env`.
