from __future__ import annotations

import json
import re

from openai import pydantic_function_tool
from pydantic import BaseModel, Field
from sqlalchemy import select

from ..db import get_session
from ..repositories.documents import DocParsed


def _normalize_title(title: str) -> str:
    return re.sub(r"\s+", " ", title.strip()).lower()


def _find_heading(full_text: str, section_title: str):
    requested = _normalize_title(section_title)
    heading_pattern = re.compile(r"^(#{1,6})\s+(.*)$", re.MULTILINE)

    # 1. 完全匹配
    for match in heading_pattern.finditer(full_text):
        level = len(match.group(1))
        raw_title = match.group(2).strip()
        if _normalize_title(raw_title) == requested:
            return {
                "level": level,
                "title": raw_title,
                "start": match.start(),
                "end": match.end(),
                "raw_heading": match.group(0).strip(),
            }

    # 2. 模糊匹配（包含）
    for match in heading_pattern.finditer(full_text):
        level = len(match.group(1))
        raw_title = match.group(2).strip()
        norm = _normalize_title(raw_title)
        if requested in norm or norm in requested:
            return {
                "level": level,
                "title": raw_title,
                "start": match.start(),
                "end": match.end(),
                "raw_heading": match.group(0).strip(),
            }

    return None


def _find_section_text(full_text: str, heading_info: dict) -> str:
    current_level = heading_info["level"]
    content_start = heading_info["end"]

    heading_pattern = re.compile(r"^(#{1,6})\s+(.*)$", re.MULTILINE)

    for match in heading_pattern.finditer(full_text, pos=content_start):
        next_level = len(match.group(1))
        if next_level <= current_level:
            return full_text[content_start:match.start()].strip()

    return full_text[content_start:].strip()


def search_paragraph(doc_id: int, section_title: str) -> str:
    with get_session() as session:
        select_by_doc_id = select(DocParsed).where(DocParsed.doc_id == doc_id)
        doc = session.execute(select_by_doc_id).scalar_one_or_none()

        if doc is None:
            return json.dumps(
                {"error": f"未找到对应ID文章, {doc_id=}"},
                ensure_ascii=False,
                indent=2,
            )

        full_text = doc.full_text or ""
        if not full_text.strip():
            return json.dumps(
                {"error": f"文章全文为空, {doc_id=}"},
                ensure_ascii=False,
                indent=2,
            )

        heading_info = _find_heading(full_text, section_title)
        if heading_info is None:
            return json.dumps(
                {
                    "error": f"未找到对应章节: {section_title=}",
                    "doc_id": doc_id,
                },
                ensure_ascii=False,
                indent=2,
            )

        section_text = _find_section_text(full_text, heading_info)

        payload = {
            "doc_id": doc_id,
            "requested_section_title": section_title,
            "matched_heading": heading_info["raw_heading"],
            "text": section_text,
        }
        return json.dumps(payload, ensure_ascii=False, indent=2)


class SearchParagraphRequest(BaseModel):
    doc_id: int = Field(..., description="文档ID")
    section_title: str = Field(..., description="章节标题，支持完整匹配和模糊匹配")


search_paragraph_tool = pydantic_function_tool(
    SearchParagraphRequest,
    name="search_paragraph",
    description="按文档ID和章节标题检索论文某一节的完整原文内容",
)