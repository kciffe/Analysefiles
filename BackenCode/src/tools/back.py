import json
from datetime import date, datetime
from typing import Any,Literal

from pydantic import BaseModel, Field


def Field(default=None, **_kwargs):
    return default

def _to_iso_date(value: date | datetime | None) -> str | None:
    if value is None:
        return None
    if isinstance(value, datetime):
        return value.date().isoformat()
    return value.isoformat()


def _serialize_document(item: Any) -> dict:
    return {
        "id": item.id,
        "title": item.title,
        "authors": item.authors,
        "abstract": item.abstract,
        "publish_year": _to_iso_date(item.publish_year),
        "keywords": item.keywords or [],
    }


def search_documents(
    keywords: list[str] | None = None,
    doc_types: list[str] | None = None,
    start_date: str | None = None,
    end_date: str | None = None,
    limit: int = 128,
) -> str:
    try:
        from ..db import get_session
        from ..repositories.documents import search_documents_by_keywords
    except ImportError:
        # Fallback for running with project root set to BackenCode/src.
        try:
            from db import get_session
            from repositories.documents import search_documents_by_keywords
        except ModuleNotFoundError as exc:
            raise RuntimeError(
                "Missing dependency. Please install sqlalchemy before calling search_documents."
            ) from exc
    except ModuleNotFoundError as exc:
        raise RuntimeError(
            "Missing dependency. Please install sqlalchemy before calling search_documents."
        ) from exc

    # Keep only supported keywords and avoid None iteration.
    allowed_keywords = {"LLM Agent", "Tool use"}
    normalized_keywords = [k for k in (keywords or []) if k in allowed_keywords]

    with get_session() as session:
        docs = search_documents_by_keywords(
            session,
            keywords=normalized_keywords or None,
            doc_types=doc_types,
            start_date=start_date,
            end_date=end_date,
            limit=limit,
        )

    payload = {
        "count": len(docs),
        "documents": [_serialize_document(item) for item in docs],
    }
    return json.dumps(payload, ensure_ascii=False)


class SearchDocumentsRequest(BaseModel):
    keywords: list[str] | None = Field(None, description="Search keywords.")
    doc_types: list[str] | None = Field(Literal["LLM Agent", "Tool use"], description="Document type filters")
    start_date: str | None = Field(None, description="Earliest publish date (ISO format: YYYY-MM-DD)")
    end_date: str | None = Field(None, description="Latest publish date (ISO format: YYYY-MM-DD)")
    limit: int = Field(128, description="Max number of documents to return")