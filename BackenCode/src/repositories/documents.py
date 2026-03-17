from __future__ import annotations

from dataclasses import dataclass
from datetime import date, datetime
from typing import Any, Mapping

from sqlalchemy import DateTime, Integer, String, Text, cast, func, or_,case, select
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, Session, mapped_column

from .base import Base

DEFAULT_SOURCE = "upload"
DEFAULT_PUBLISH_VENUE = "unknown"



# 文件原始资源
class FileResource(Base):
    __tablename__ = "file_resource"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    path: Mapped[str] = mapped_column(String(256))
    name: Mapped[str] = mapped_column(String(128))
    type: Mapped[str | None] = mapped_column(String(16))
    source: Mapped[str] = mapped_column(String(64))
    created_time: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now()
    )

# 文档元数据，主要关联表
class FileMetadata(Base):
    __tablename__ = "file_metadata"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    file_id: Mapped[int] = mapped_column(Integer)
    source: Mapped[str] = mapped_column(String(64))
    title: Mapped[str] = mapped_column(String(256))
    authors: Mapped[str | None] = mapped_column(String(255))
    institutions: Mapped[str | None] = mapped_column(String(255))
    publish_year: Mapped[datetime | None] = mapped_column(DateTime)
    publish_venue: Mapped[str] = mapped_column(String(64))
    keywords: Mapped[list[str]] = mapped_column(JSONB, default=list)
    abstract: Mapped[str | None] = mapped_column(Text)
    language: Mapped[str | None] = mapped_column(String(32))
    created_time: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now()
    )
    update_time: Mapped[datetime] = mapped_column(DateTime)

# 文档解析结果
class DocParsed(Base):
    __tablename__ = "doc_parsed"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    doc_id: Mapped[int] = mapped_column(Integer)
    full_text: Mapped[str] = mapped_column(Text)
    structure_info: Mapped[dict[str, Any]] = mapped_column(JSONB)
    parse_time: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
    status: Mapped[str] = mapped_column(String(32))
    error_info: Mapped[str | None] = mapped_column(Text)

# Agent日志表
class AgentLogs(Base):
    __tablename__="agent_logs"
    id : Mapped[int] = mapped_column(Integer, primary_key=True)
    task_name:Mapped[str] = mapped_column(String(64))
    status: Mapped[str] = mapped_column(String(16))
    messaage: Mapped[str] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
    
@dataclass(frozen=True)
class StoredDocument:
    file_resource_id: int
    file_metadata_id: int
    doc_parsed_id: int


@dataclass(frozen=True)
class RetrievedDocument:
    id: int
    name: str
    path: str
    doc_type: str | None
    title: str
    keywords: list[str]
    full_text: str


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

    # Serialize id allocation across the three tables.
    session.execute(select(func.pg_advisory_xact_lock(_DOCUMENTS_WRITE_LOCK_ID)))

    ids = _allocate_document_ids(session)

    file_resource = FileResource(
        id=ids.file_resource_id,
        path=file_path,
        name=file_name,
        type=doc_type,
        source=normalized_metadata["source"],
    )
    file_metadata = FileMetadata(
        id=ids.file_metadata_id,
        file_id=ids.file_resource_id,
        source=normalized_metadata["source"],
        title=normalized_metadata["title"],
        authors=normalized_metadata["authors"],
        institutions=normalized_metadata["institutions"],
        publish_year=normalized_metadata["publish_year"],
        publish_venue=normalized_metadata["publish_venue"],
        keywords=normalized_metadata["keywords"],
        abstract=normalized_metadata["abstract"],
        language=normalized_metadata["language"],
        update_time=update_time,
    )
    doc_parsed = DocParsed(
        id=ids.doc_parsed_id,
        doc_id=ids.file_resource_id,
        full_text=full_text,
        structure_info=dict(structure_info),
        status="success",
        error_info=None,
    )

    session.add_all([file_resource, file_metadata, doc_parsed])

    return StoredDocument(
        file_resource_id=ids.file_resource_id,
        file_metadata_id=ids.file_metadata_id,
        doc_parsed_id=ids.doc_parsed_id,
    )



def search_documents_by_keywords(
    session: Session,
    *,
    keywords: list[str] ,
    doc_types: list[str] | None = None,
    start_date: date | str | None = None,
    end_date: date | str | None = None,
    limit: int = 128,
) -> list[RetrievedDocument]:
    query_all_tables = (
        select(FileResource, FileMetadata, DocParsed)
        .join(FileMetadata, FileMetadata.file_id == FileResource.id)
        .join(DocParsed, DocParsed.doc_id == FileResource.id)
    )

    #关键词匹配
    normalized_keywords=[]
    for keyword in keywords:
        if keyword and keyword.strip():
            normalized_keywords.append(keyword.strip())

    if normalized_keywords:
        score=0
        for keyword in normalized_keywords:
            wildcard = f"%{keyword}%"
            score+=(
                case((FileMetadata.title.ilike(wildcard),3),else_=0)+
                case((cast(FileMetadata.keywords,Text).ilike(wildcard),2),else_=0)+
                case((FileMetadata.abstract.ilike(wildcard),1),else_=0)
            )
        score=score.label("score")
        query_all_tables=(
            query_all_tables.add_columns(score)
            .where(score>0)
            .order_by(score.desc())
        )
    else:
        query_all_tables=query_all_tables.order_by(FileMetadata.publish_year.desc())

    #文档类型匹配
    normalized_doc_types = []
    for doc_type in (doc_types or []):
        if doc_type :
            normalized_doc_types.append(doc_type)
    if normalized_doc_types:
        query_all_tables=query_all_tables.where(FileResource.type.in_(normalized_doc_types))

    normalized_start_date = _normalize_date(start_date)
    normalized_end_date = _normalize_date(end_date)

    #时间匹配
    if normalized_start_date is not None:
        query_all_tables = query_all_tables.where(
            FileMetadata.publish_year
            >= datetime.combine(normalized_start_date, datetime.min.time())
        )
    if normalized_end_date is not None:
        query_all_tables = query_all_tables.where(
            FileMetadata.publish_year
            <= datetime.combine(normalized_end_date, datetime.max.time())
        )

    rows = session.execute(query_all_tables.limit(limit)).all()

    # rows 每一行：
    # (FileResource, FileMetadata, DocParsed, score)
    # ↓ for 循环拆包
    # ↓ 构造 RetrievedDocument
    # ↓ 放进 list
    # ↓ return 返回
    return [
        RetrievedDocument(
            id=file_resource.id,
            name=file_resource.name,
            path=file_resource.path,
            doc_type=file_resource.type,
            title=file_metadata.title,
            keywords=list(file_metadata.keywords or []),
            full_text=doc_parsed.full_text,
        )
        for file_resource, file_metadata, doc_parsed, _score in rows
    ]

#文档写入专用锁
_DOCUMENTS_WRITE_LOCK_ID = 100100


@dataclass(frozen=True)
class DocumentIds:
    file_resource_id: int
    file_metadata_id: int
    doc_parsed_id: int


def _allocate_document_ids(session: Session) -> DocumentIds:
    file_resource_id = _next_file_resource_id(session)
    file_metadata_id = _next_file_metadata_id(session)
    doc_parsed_id = _next_doc_parsed_id(session)
    return DocumentIds(
        file_resource_id=file_resource_id,
        file_metadata_id=file_metadata_id,
        doc_parsed_id=doc_parsed_id,
    )


def _next_file_resource_id(session: Session) -> int:
    return _select_next_id(session, FileResource.id)


def _next_file_metadata_id(session: Session) -> int:
    return _select_next_id(session, FileMetadata.id)


def _next_doc_parsed_id(session: Session) -> int:
    return _select_next_id(session, DocParsed.id)


def _select_next_id(session: Session, column) -> int:
    stmt = select(func.coalesce(func.max(column), 0) + 1)
    return int(session.execute(stmt).scalar_one())


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


def _normalize_date(value: date | str | None) -> date | None:
    if value is None:
        return None
    if isinstance(value, date):
        return value
    if isinstance(value, str):
        try:
            return date.fromisoformat(value)
        except ValueError:
            return None
    return None


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
