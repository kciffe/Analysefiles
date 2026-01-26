from fastapi import FastAPI
from .docs_api import doc_router
from .query import query_router

app = FastAPI()
app.include_router(doc_router)
app.include_router(query_router)