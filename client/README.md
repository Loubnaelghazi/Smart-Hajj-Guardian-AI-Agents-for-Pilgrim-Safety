# Smart Hajj Guardian Admin Dashboard

React/Vite command center for the Hajj agency/guide interface.

## Setup

Copy the provided `src/` directory into your existing Vite React project, or use this project directly.

Install:

```bash
npm install
npm install lucide-react
```

Create `.env`:

```env
VITE_API_BASE_URL=http://localhost:8000
VITE_AGENCY_ID=demo-agency-001
```

Run:

```bash
npm run dev
```

Default Vite URL:

http://localhost:5173

## Backend requirement

FastAPI needs CORS enabled for the React development server.

Add to `backend/main.py`:

```python
from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:5173",
        "http://127.0.0.1:5173",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

## API endpoints used

- GET `/api/agencies/{agency_id}/overview`
- PATCH `/api/incidents/{incident_id}/acknowledge`
- PATCH `/api/incidents/{incident_id}/resolve`

The API service also includes helpers for:
- GET `/api/groups/{group_id}`
- GET `/api/groups/{group_id}/pilgrims`
- GET `/api/incidents/active`
- GET `/api/incidents/{incident_id}`
