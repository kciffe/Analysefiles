import os
from typing import Literal,Any
import json
from datetime import date, datetime
from openai import pydantic_function_tool, OpenAI
from pydantic import BaseModel, Field
from ..repositories.documents import search_documents_by_keywords
from ..db import get_session

#TODO: 规范search_documents输出结果为字符串✅
#description丰富 ✅
#检索工具返回格式：题目、作者、摘要、发布时间、论文目录结构 、关键词✅
#段落检索工具
#中间工具调用过程持久化
#langgraph实现控制循环
def search_documents(
    keywords: list[str] | None = None,
    doc_types: list[str] | None = None,
    start_date: str | None = None,
    end_date: str | None = None,
    limit: int = 128,
):
    for keyword in (keywords or []):
        if keyword not in ["LLM Agent", "Tool use"]:
            return f"{keyword} is not in [LLM Agent, Tool use]"
    with get_session() as session:
        docs=search_documents_by_keywords(
            session,
            keywords=keywords,
            doc_types=doc_types,
            start_date=start_date,
            end_date=end_date,
            limit=limit,
        )
        payload=[_serialize_document(doc) for doc in docs]
        return json.dumps(payload, ensure_ascii=False,indent=2)

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
        "structure_info": item.structure_info or {},
    }

class SearchDocumentsRequest(BaseModel):
    keywords: list[str] | None = Field(None, description="搜索的关键词")
    doc_types: list[str] | None = Field(None, description="文档类型,如ACL、arxiv等")
    start_date: str | None = Field(None, description="文档发布的最早时间")
    end_date: str | None = Field(None, description="文档发布的最晚时间")
    limit: int = Field(128, description="返回的文档数量上限")


search_documents_tool = pydantic_function_tool(
    SearchDocumentsRequest,
    name="search_docs",
    description="搜索文档工具，依据需求描述，返回满足条件的文档信息",
)
