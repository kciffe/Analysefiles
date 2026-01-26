from fastapi import APIRouter
from .query_labels import router

query_router = APIRouter(prefix="/query")
query_router.include_router(router)