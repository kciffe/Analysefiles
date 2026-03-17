from fastapi import APIRouter

from .submit import router as submit_router

requirement_router = APIRouter(prefix="/requirements")
requirement_router.include_router(submit_router)
