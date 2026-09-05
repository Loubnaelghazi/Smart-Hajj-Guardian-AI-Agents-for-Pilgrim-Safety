import os

from pymongo import MongoClient
from pymongo.database import Database


MONGODB_URI = os.getenv(
    "MONGODB_URI",
    "mongodb://guardian:guardian_dev_password@localhost:27017/?authSource=admin",
)

MONGODB_DATABASE = os.getenv(
    "MONGODB_DATABASE",
    "smart_hajj_guardian",
)


client = MongoClient(
    MONGODB_URI,
    serverSelectionTimeoutMS=5000,
)

db: Database = client[MONGODB_DATABASE]


def ping_database() -> bool:
    client.admin.command("ping")
    return True


def create_indexes() -> None:
    db.agencies.create_index("id", unique=True)
    db.guides.create_index("id", unique=True)
    db.guides.create_index("agency_id")
    db.groups.create_index("id", unique=True)
    db.groups.create_index("agency_id")
    db.groups.create_index("guide_id")
    db.pilgrims.create_index("id", unique=True)
    db.pilgrims.create_index("phone_number", unique=True)
    db.pilgrims.create_index("agency_id")
    db.pilgrims.create_index("group_id")
    db.safe_zones.create_index("id", unique=True)
    db.safe_zones.create_index("group_id")
    db.incidents.create_index("id", unique=True)
    db.incidents.create_index("agency_id")
    db.incidents.create_index("group_id")
    db.incidents.create_index("pilgrim_id")
    db.incidents.create_index("status")
    