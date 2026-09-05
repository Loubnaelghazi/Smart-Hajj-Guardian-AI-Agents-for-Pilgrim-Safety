import os
from pathlib import Path

from dotenv import load_dotenv


BASE_DIR = Path(__file__).resolve().parent.parent
ENV_FILE = BASE_DIR / ".env"

load_dotenv(
    ENV_FILE,
    override=True,
)


NOKIA_API_KEY = os.getenv(
    "NOKIA_API_KEY",
    "",
).strip()

NOKIA_API_HOST = os.getenv(
    "NOKIA_API_HOST",
    "network-as-code.nokia.rapidapi.com",
).strip()

NOKIA_BASE_URL = os.getenv(
    "NOKIA_BASE_URL",
    "https://network-as-code.p-eu.apihub.nokia.io",
).strip()
# =========================================================
# CONGESTION
# =========================================================

CONGESTION_CALLBACK_URL = os.getenv(
    "CONGESTION_CALLBACK_URL",
    "http://example.com/notify",
)

CONGESTION_AUTH_TOKEN = os.getenv(
    "CONGESTION_AUTH_TOKEN",
    "smart-hajj-guardian-demo-token",
)


# Nokia simulator number that we validated successfully
# against Congestion Insights.
CONGESTION_DEVICE_PHONE = os.getenv(
    "CONGESTION_DEVICE_PHONE",
    "+36719991000",
)


# =========================================================
# CACHE
# =========================================================

LOCATION_VERIFY_CACHE_SECONDS = int(
    os.getenv(
        "LOCATION_VERIFY_CACHE_SECONDS",
        "60",
    )
)

REACHABILITY_CACHE_SECONDS = int(
    os.getenv(
        "REACHABILITY_CACHE_SECONDS",
        "30",
    )
)

CONGESTION_CACHE_SECONDS = int(
    os.getenv(
        "CONGESTION_CACHE_SECONDS",
        "180",
    )
)


# =========================================================
# QOD
# =========================================================

QOD_PUBLIC_ADDRESS = os.getenv(
    "QOD_PUBLIC_ADDRESS",
    "233.252.0.2",
)

QOD_PRIVATE_ADDRESS = os.getenv(
    "QOD_PRIVATE_ADDRESS",
    "192.0.2.25",
)

QOD_PUBLIC_PORT = int(
    os.getenv(
        "QOD_PUBLIC_PORT",
        "80",
    )
)

QOD_APPLICATION_SERVER_IPV4 = os.getenv(
    "QOD_APPLICATION_SERVER_IPV4",
    "8.8.8.8",
)

QOD_PROFILE = os.getenv(
    "QOD_PROFILE",
    "DOWNLINK_M_UPLINK_L",
)

QOD_DURATION = int(
    os.getenv(
        "QOD_DURATION",
        "60",
    )
)