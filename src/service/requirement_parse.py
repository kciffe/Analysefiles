from __future__ import annotations

import json
import os
import re
from pathlib import Path
from textwrap import dedent
from typing import Any

from openai import OpenAI

from src.db import get_session
from src.repositories.documents import RetrievedDocument, search_documents_by_keywords

_SYSTEM_PROMPT = dedent(
    """
    你是一个需求分析助手。
    你会收到：
    1) 用户的需求信息
    2) 数据库检索得到的文档列表（标题、关键词、正文片段）

    你的任务：
    - 基于需求信息，分析这些文档与需求的相关性和支撑结论。
    - 输出“类似 ChatGPT 的 blocks 报告结构”。

    输出约束：
    1. 只输出合法 JSON，不要 markdown 代码块。
    2. JSON 必须严格符合以下结构：
    {
      "success": true,
      "report": {
        "title": "...",
        "summary": "...",
        "blocks": [
          {
            "id": "block_1",
            "type": "text",
            "title": "...",
            "content": "..."
          },
          {
            "id": "block_2",
            "type": "table",
            "title": "...",
            "columns": ["..."],
            "rows": [["..."]]
          }
        ]
      }
    }
    """
).strip()


def analyze_requirement(requirement_data: dict[str, Any]) -> dict[str, Any]:
    keywords = requirement_data.get("keywords") or []
    doc_types = requirement_data.get("docTypes") or []

    with get_session() as session:
        documents = search_documents_by_keywords(
            session,
            keywords=keywords,
            doc_types=doc_types,
            start_date=requirement_data.get("startDate"),
            end_date=requirement_data.get("endDate"),
            limit=8,
        )

    if not documents:
        return _empty_report(requirement_data)

    return _analyze_with_openclaw(requirement_data, documents)


def _analyze_with_openclaw(
    requirement_data: dict[str, Any], documents: list[RetrievedDocument]
) -> dict[str, Any]:
    base_url, api_key, model = _resolve_openclaw_config()
    client = OpenAI(base_url=base_url, api_key=api_key)

    payload = {
        "requirement": {
            "name": requirement_data.get("name"),
            "keywords": requirement_data.get("keywords") or [],
            "docTypes": requirement_data.get("docTypes") or [],
            "startDate": requirement_data.get("startDate"),
            "endDate": requirement_data.get("endDate"),
            "detail": requirement_data.get("detail") or "",
        },
        "documents": [
            {
                "id": doc.id,
                "name": doc.name,
                "title": doc.title,
                "docType": doc.doc_type,
                "keywords": doc.keywords,
                "contentSnippet": _doc_snippet(doc.full_text),
            }
            for doc in documents
        ],
    }

    completion = client.chat.completions.create(
        model=model,
        messages=[
            {"role": "system", "content": _SYSTEM_PROMPT},
            {
                "role": "user",
                "content": (
                    "请根据以下需求和候选文档输出最终需求分析报告 JSON：\n"
                    + json.dumps(payload, ensure_ascii=False)
                ),
            },
        ],
    )

    content = completion.choices[0].message.content or ""
    normalized = _clean_llm_output(content)

    result = json.loads(normalized)
    if not isinstance(result, dict):
        raise ValueError("OpenClaw output is not a JSON object.")
    return result


def _doc_snippet(full_text: str, max_len: int = 2500) -> str:
    text = full_text.strip()
    if len(text) <= max_len:
        return text
    return text[:max_len] + "..."


def _resolve_openclaw_config() -> tuple[str, str, str]:
    env_base_url = os.getenv("OPENCLAW_BASE_URL")
    env_api_key = os.getenv("OPENCLAW_API_KEY")
    env_model = os.getenv("OPENCLAW_MODEL")

    if env_base_url and env_api_key and env_model:
        return env_base_url, env_api_key, env_model

    cfg = _load_openclaw_json_defaults()
    base_url = env_base_url or cfg.get("base_url") or "https://dashscope.aliyuncs.com/compatible-mode/v1"
    api_key = env_api_key or cfg.get("api_key") or ""
    model = env_model or cfg.get("model") or "qwen-max"

    if not api_key:
        raise ValueError(
            "Missing OPENCLAW_API_KEY. Set OPENCLAW_BASE_URL/OPENCLAW_API_KEY/OPENCLAW_MODEL "
            "or configure ~/.openclaw/openclaw.json."
        )

    return base_url, api_key, model


def _load_openclaw_json_defaults() -> dict[str, str]:
    config_path = Path.home() / ".openclaw" / "openclaw.json"
    if not config_path.exists():
        return {}

    try:
        data = json.loads(config_path.read_text(encoding="utf-8"))
    except Exception:
        return {}

    providers = data.get("models", {}).get("providers", {})
    primary = (
        data.get("agents", {})
        .get("defaults", {})
        .get("model", {})
        .get("primary", "")
    )
    provider_name, _, model_id = primary.partition("/")
    provider_cfg = providers.get(provider_name, {}) if provider_name else {}

    api_key = provider_cfg.get("apiKey") or ""
    if api_key == "qwen-oauth":
        api_key = ""

    return {
        "base_url": provider_cfg.get("baseUrl") or "",
        "api_key": api_key,
        "model": model_id or "",
    }


def _clean_llm_output(content: str) -> str:
    cleaned = re.sub(r"<think>.*?</think>", "", content, flags=re.DOTALL).strip()
    if cleaned.startswith("```"):
        cleaned = re.sub(r"^```(?:json)?\s*", "", cleaned)
        cleaned = re.sub(r"\s*```$", "", cleaned)
    return cleaned.strip()


def _empty_report(requirement_data: dict[str, Any]) -> dict[str, Any]:
    return {
        "success": True,
        "report": {
            "title": f"{requirement_data.get('name', '需求')}分析报告",
            "summary": "未检索到匹配文献。",
            "blocks": [
                {
                    "id": "block_1",
                    "type": "text",
                    "title": "结果说明",
                    "content": "根据当前关键词、时间范围与文档类型未找到匹配文献，请调整筛选条件后重试。",
                }
            ],
        },
    }
