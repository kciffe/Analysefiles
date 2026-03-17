from fastapi import APIRouter
from .upload import router as upload_router

doc_router = APIRouter(prefix="/docs")
doc_router.include_router(upload_router, prefix="/upload")
