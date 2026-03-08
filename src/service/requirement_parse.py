from __future__ import annotations

import json
import os
import re
from pathlib import Path
from textwrap import dedent

from openai import OpenAI

_SYSTEM_PROMPT = dedent(
    """
    You are a requirement analysis assistant. Convert the requirement object to a structured report JSON.
    Output constraints:
    1. Only output valid JSON.
    2. Do not wrap with markdown code fences.
    3. Use this exact schema:
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


def analyze_requirement(requirement_data: dict) -> dict:
    base_url, api_key, model = _resolve_openclaw_config()

    client = OpenAI(base_url=base_url, api_key=api_key)

    completions = client.chat.completions.create(
        model=model,
        messages=[
            {"role": "system", "content": _SYSTEM_PROMPT},
            {
                "role": "user",
                "content": (
                    "Analyze this requirement object and return JSON only:\n"
                    + json.dumps(requirement_data, ensure_ascii=False)
                ),
            },
        ],
    )

    content = completions.choices[0].message.content or ""
    normalized = _clean_llm_output(content)

    result = json.loads(normalized)
    if not isinstance(result, dict):
        raise ValueError("OpenClaw output is not a JSON object.")

    return result


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
