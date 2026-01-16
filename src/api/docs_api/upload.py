from __future__ import annotations

import inspect
import os
from pathlib import Path
from typing import Any, Mapping
from uuid import uuid4

from fastapi import APIRouter, File, Form, HTTPException, UploadFile

from src.db import get_session
from src.repositories.documents import store_parsed_document
from src.service.parse import ParseService
from .schemas import ParseResponse
from ..schemas import ResponseModel

UPLOAD_DIR = Path(os.getenv("UPLOAD_DIR", "data/uploads"))

router = APIRouter()


@router.post("/parse", response_model=ResponseModel[ParseResponse])
async def parse_doc(
    file: UploadFile = File(...), doc_type: str = Form(...)
) -> ParseResponse:
    file_bytes = await file.read()
    if not file_bytes:
        raise HTTPException(status_code=400, detail="Empty file upload.")

    safe_name = _safe_filename(file.filename)
    stored_path = _save_upload(file_bytes, safe_name)

    parse_service = ParseService()
    try:
        parse_result = parse_service.run(
            file_bytes=file_bytes, file_name=safe_name, doc_type=doc_type
        )
        if inspect.isawaitable(parse_result):
            parse_result = await parse_result
    except Exception as exc:
        raise HTTPException(status_code=500, detail="Document parsing failed.") from exc

    normalized = _normalize_parse_result(parse_result)

    # with get_session() as session:
    #     store_parsed_document(
    #         session,
    #         file_path=str(stored_path),
    #         file_name=safe_name,
    #         doc_type=doc_type,
    #         full_text=normalized["full_text"],
    #         structure_info=normalized["structure_info"],
    #         metadata=normalized["metadata"],
    #     )
    
    return ResponseModel(
        code=200,
        data=ParseResponse(md=normalized["full_text"])
    )


def _safe_filename(filename: str | None) -> str:
    if not filename:
        return "upload.bin"
    return Path(filename).name


def _save_upload(file_bytes: bytes, filename: str) -> Path:
    UPLOAD_DIR.mkdir(parents=True, exist_ok=True)
    stored_name = f"{uuid4().hex}_{filename}"
    stored_path = UPLOAD_DIR / stored_name
    stored_path.write_bytes(file_bytes)
    return stored_path


def _normalize_parse_result(parse_result: Any) -> dict[str, Any]:
    if hasattr(parse_result, "model_dump"):
        data = parse_result.model_dump()
    elif isinstance(parse_result, Mapping):
        data = dict(parse_result)
    else:
        raise HTTPException(
            status_code=500,
            detail="Parse service returned an unsupported result.",
        )

    full_text = data.get("full_text") or ""
    structure_info = data.get("structure_info") or {}
    metadata = data.get("metadata") or {}

    if not isinstance(structure_info, Mapping):
        raise HTTPException(
            status_code=500,
            detail="Parse service returned invalid structure_info.",
        )

    if not isinstance(metadata, Mapping):
        metadata = {}

    return {
        "full_text": full_text,
        "structure_info": dict(structure_info),
        "metadata": dict(metadata),
    }
