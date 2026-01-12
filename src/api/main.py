from fastapi import FastAPI
from .docs_api import doc_router

app = FastAPI()
app.include_router(doc_router)
