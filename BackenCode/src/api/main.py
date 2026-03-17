from fastapi import FastAPI
from .docs_api import doc_router
from .query import query_router
from .requirement_api import requirement_router

app = FastAPI()
app.include_router(doc_router)
app.include_router(query_router)
app.include_router(requirement_router)
