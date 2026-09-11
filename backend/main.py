from pathlib import Path

from fastapi import FastAPI, HTTPException, Request
from .mobile_observations import router as mobile_router, apply_device_distance
from .briefing import router as briefing_router
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates

from .database import create_indexes, ping_database
from .guardian_graph import GuardianWorkflow
from .memory_agent import MemoryAgent
from .models import (
    CongestionRequest,
    ConsentStatusRequest,
    GuardianAnalyzeRequest,
    LocationRequest,
    LocationVerificationRequest,
    PhoneRequest,
    QoDCreateRequest,
    SOSRequest,
)
from .nokia_client import NokiaAPIError, NokiaClient
from .repositories import seed_demo_data
from .routes.operations import router as operations_router
from .state_store import PilgrimStateStore
from .telecom_cache import TelecomCache
from fastapi.middleware.cors import CORSMiddleware


app = FastAPI(
    title="Smart Hajj Guardian Hackathon Backend",
    version="0.7.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:5173",
        "http://127.0.0.1:5173",
        "https://smart-hajj-dashboard.onrender.com",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(operations_router)
app.include_router(mobile_router)
app.include_router(briefing_router)

BASE_DIR = Path(__file__).resolve().parent

templates = Jinja2Templates(directory=str(BASE_DIR / "templates"))

nokia = NokiaClient()
store = PilgrimStateStore()
cache = TelecomCache()
memory = MemoryAgent()

guardian = GuardianWorkflow(
    nokia=nokia,
    store=store,
    cache=cache,
    memory=memory,
)


@app.on_event("startup")
async def initialize_application():
    ping_database()
    create_indexes()
    seed_demo_data()


def api_error(exc: NokiaAPIError):
    raise HTTPException(
        status_code=exc.status_code,
        detail=exc.detail,
    )


@app.get(
    "/",
    response_class=HTMLResponse,
)
async def home(
    request: Request,
):
    return templates.TemplateResponse(
        request=request,
        name="index.html",
        context={},
    )

@app.get("/health")
async def health():
    mongodb_ok = False

    try:
        mongodb_ok = ping_database()
    except Exception:
        mongodb_ok = False

    return {
        "status": "ok",
        "version": "0.7.0",
        "mongodb": mongodb_ok,
        "real_nokia": [
            "location-verification",
            "device-reachability",
            "congestion-insights",
            "quality-on-demand",
            "consent-info",
        ],
        "optional": ["location-retrieval"],
        "geofencing_subscription": (
            "Not used in demo because Nokia simulator callback "
            "hostname is currently invalid."
        ),
        "replacement_for_demo": "location-verification",
        "langgraph": True,
        "cache_entries": cache.count(),
        "demo_agency_id": "demo-agency-001",
        "demo_group_id": "demo-group-001",
        "demo_pilgrim_id": "demo-pilgrim-001",
        "demo_phone_number": "+99999991000",
    }


@app.post("/api/location")
async def location(body: LocationRequest):
    try:
        return await nokia.retrieve_location(body.phone_number, body.max_age)
    except NokiaAPIError as exc:
        api_error(exc)


@app.post("/api/location/verify")
async def location_verify(body: LocationVerificationRequest):
    try:
        return await nokia.verify_location(
            phone_number=body.phone_number,
            latitude=body.area.latitude,
            longitude=body.area.longitude,
            radius=body.area.radius,
            max_age=body.max_age,
        )
    except NokiaAPIError as exc:
        api_error(exc)


@app.post("/api/reachability")
async def reachability(body: PhoneRequest):
    try:
        return await nokia.retrieve_reachability(body.phone_number)
    except NokiaAPIError as exc:
        api_error(exc)


@app.post("/api/consent/status")
async def consent_status(body: ConsentStatusRequest):
    try:
        return await nokia.retrieve_consent_status(
            body.phone_number,
            body.scopes,
            body.purpose,
            body.request_capture_url,
        )
    except NokiaAPIError as exc:
        api_error(exc)


@app.post("/api/congestion/query")
async def congestion_query(body: CongestionRequest):
    try:
        return await nokia.query_congestion(
            body.phone_number,
            body.subscription_expire_time,
        )
    except NokiaAPIError as exc:
        api_error(exc)


@app.post("/api/congestion/subscriptions")
async def congestion_subscription(body: CongestionRequest):
    try:
        return await nokia.create_congestion_subscription(
            body.phone_number,
            body.subscription_expire_time,
        )
    except NokiaAPIError as exc:
        api_error(exc)


@app.post("/api/qod/sessions")
async def create_qod(body: QoDCreateRequest):
    try:
        return await nokia.create_qod_session(
            body.phone_number,
            body.ipv4.public_address,
            body.ipv4.private_address,
            body.ipv4.public_port,
            body.application_server_ipv4,
            body.qos_profile,
            body.duration,
        )
    except NokiaAPIError as exc:
        api_error(exc)


@app.post("/api/guardian/analyze")
async def guardian_analyze(body: GuardianAnalyzeRequest):
    return await guardian.analyze(
        phone_number=body.phone_number,
        distance_from_group_m=apply_device_distance(store, body.phone_number, body.distance_from_group_m),
        safe_area={
            "latitude": body.safe_area.latitude,
            "longitude": body.safe_area.longitude,
            "radius": body.safe_area.radius,
        },
        max_location_age=body.max_location_age,
        sos=False,
    )


@app.post("/api/guardian/sos")
async def guardian_sos(body: SOSRequest):
    return await guardian.analyze(
        phone_number=body.phone_number,
        distance_from_group_m=apply_device_distance(store, body.phone_number, body.distance_from_group_m),
        safe_area={
            "latitude": body.safe_area.latitude,
            "longitude": body.safe_area.longitude,
            "radius": body.safe_area.radius,
        },
        max_location_age=120,
        sos=True,
    )


@app.get("/api/pilgrims")
async def pilgrims():
    states = store.all()
    return {
        "count": len(states),
        "pilgrims": states,
    }


@app.delete("/api/cache")
async def clear_cache():
    cache.clear()
    return {"status": "cache-cleared"}


@app.get("/api/memory/{phone_number}")
async def memory_history(phone_number: str):
    return {
        "phone_number": phone_number,
        "memory": memory.summary(phone_number),
    }


@app.delete("/api/memory")
async def clear_memory():
    memory.clear()
    return {"status": "memory-cleared"}
