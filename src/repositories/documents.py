from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from typing import Any, Mapping

from sqlalchemy import bindparam, text
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Session

DEFAULT_SOURCE = "upload"
DEFAULT_PUBLISH_VENUE = "unknown"


@dataclass(frozen=True)
class StoredDocument:
    file_resource_id: int
    file_metadata_id: int
    doc_parsed_id: int


def store_parsed_document(
    session: Session,
    *,
    file_path: str,
    file_name: str,
    doc_type: str | None,
    full_text: str,
    structure_info: Mapping[str, Any],
    metadata: Mapping[str, Any] | None,
) -> StoredDocument:
    normalized_metadata = _normalize_metadata(metadata, default_title=file_name)
    update_time = datetime.utcnow()

    session.execute(_LOCK_TABLES_SQL)
    file_resource_id = _next_id(session, "file_resource")
    file_metadata_id = _next_id(session, "file_metadata")
    doc_parsed_id = _next_id(session, "doc_parsed")

    session.execute(
        _FILE_RESOURCE_INSERT,
        {
            "id": file_resource_id,
            "path": file_path,
            "name": file_name,
            "type": doc_type,
            "source": normalized_metadata["source"],
        },
    )

    session.execute(
        _FILE_METADATA_INSERT,
        {
            "id": file_metadata_id,
            "file_id": file_resource_id,
            "source": normalized_metadata["source"],
            "title": normalized_metadata["title"],
            "authors": normalized_metadata["authors"],
            "institutions": normalized_metadata["institutions"],
            "publish_year": normalized_metadata["publish_year"],
            "publish_venue": normalized_metadata["publish_venue"],
            "keywords": normalized_metadata["keywords"],
            "abstract": normalized_metadata["abstract"],
            "language": normalized_metadata["language"],
            "update_time": update_time,
        },
    )

    session.execute(
        _DOC_PARSED_INSERT,
        {
            "id": doc_parsed_id,
            "doc_id": file_resource_id,
            "full_text": full_text,
            "structure_info": structure_info,
            "status": "success",
            "error_info": None,
        },
    )

    return StoredDocument(
        file_resource_id=file_resource_id,
        file_metadata_id=file_metadata_id,
        doc_parsed_id=doc_parsed_id,
    )


def _next_id(session: Session, table_name: str) -> int:
    stmt = _NEXT_ID_STATEMENTS.get(table_name)
    if stmt is None:
        raise ValueError(f"Unknown table for id allocation: {table_name}")
    return int(session.execute(stmt).scalar_one())


_LOCK_TABLES_SQL = text(
    "LOCK TABLE file_resource, file_metadata, doc_parsed IN EXCLUSIVE MODE"
)
_NEXT_ID_STATEMENTS = {
    "file_resource": text("SELECT COALESCE(MAX(id), 0) + 1 FROM file_resource"),
    "file_metadata": text("SELECT COALESCE(MAX(id), 0) + 1 FROM file_metadata"),
    "doc_parsed": text("SELECT COALESCE(MAX(id), 0) + 1 FROM doc_parsed"),
}
_FILE_RESOURCE_INSERT = text(
    """
    INSERT INTO file_resource (id, path, name, type, source)
    VALUES (:id, :path, :name, :type, :source)
    """
)
_FILE_METADATA_INSERT = text(
    """
    INSERT INTO file_metadata (
        id,
        file_id,
        source,
        title,
        authors,
        institutions,
        publish_year,
        publish_venue,
        keywords,
        abstract,
        language,
        update_time
    )
    VALUES (
        :id,
        :file_id,
        :source,
        :title,
        :authors,
        :institutions,
        :publish_year,
        :publish_venue,
        :keywords,
        :abstract,
        :language,
        :update_time
    )
    """
).bindparams(bindparam("keywords", type_=JSONB))
_DOC_PARSED_INSERT = text(
    """
    INSERT INTO doc_parsed (
        id,
        doc_id,
        full_text,
        structure_info,
        status,
        error_info
    )
    VALUES (
        :id,
        :doc_id,
        :full_text,
        :structure_info,
        :status,
        :error_info
    )
    """
).bindparams(bindparam("structure_info", type_=JSONB))


def _normalize_metadata(
    metadata: Mapping[str, Any] | None, *, default_title: str
) -> dict[str, Any]:
    values = dict(metadata or {})
    source = str(values.get("source") or DEFAULT_SOURCE)
    title = str(values.get("title") or default_title)

    authors = _stringify_list(values.get("authors"))
    institutions = _stringify_list(values.get("institutions"))
    publish_year = _normalize_publish_year(values.get("publish_year"))
    publish_venue = str(values.get("publish_venue") or DEFAULT_PUBLISH_VENUE)
    keywords = _normalize_keywords(values.get("keywords"))
    abstract = _stringify_value(values.get("abstract"))
    language = _stringify_value(values.get("language"))

    return {
        "source": source,
        "title": title,
        "authors": authors,
        "institutions": institutions,
        "publish_year": publish_year,
        "publish_venue": publish_venue,
        "keywords": keywords,
        "abstract": abstract,
        "language": language,
    }


def _stringify_list(value: Any) -> str | None:
    if value is None:
        return None
    if isinstance(value, str):
        return value
    if isinstance(value, (list, tuple)):
        return ", ".join(str(item) for item in value if item is not None)
    return str(value)


def _stringify_value(value: Any) -> str | None:
    if value is None:
        return None
    return str(value)


def _normalize_keywords(value: Any) -> list[str]:
    if value is None:
        return []
    if isinstance(value, (list, tuple)):
        return [str(item) for item in value if item is not None]
    if isinstance(value, str):
        return [value]
    return [str(value)]


def _normalize_publish_year(value: Any) -> datetime | None:
    if value is None:
        return None
    if isinstance(value, datetime):
        return value
    if isinstance(value, int):
        if 1 <= value <= 9999:
            return datetime(value, 1, 1)
        return None
    if isinstance(value, str):
        digits = "".join(ch for ch in value if ch.isdigit())
        if len(digits) >= 4:
            year = int(digits[:4])
            if 1 <= year <= 9999:
                return datetime(year, 1, 1)
    return None
