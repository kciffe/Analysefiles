from __future__ import annotations

from typing import Any

from src.db import get_session
from src.repositories.documents import RetrievedDocument, search_documents_by_keywords
from src.repositories.labels import select_labels_by_filters
from src.service.parse import analyze_with_openclaw


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
            limit=5,
        )

        label_keyword = keywords[0] if keywords else None
        related_labels = select_labels_by_filters(session, keyword=label_keyword)

    if not documents:
        return _empty_report(requirement_data)

    analyses = [_analyze_document(document) for document in documents]

    report = {
        "title": f"{requirement_data.get('name', '需求')}分析报告",
        "summary": f"共检索到 {len(documents)} 篇文献并完成 OpenClaw 分析。",
        "blocks": [
            {
                "id": "block_1",
                "type": "text",
                "title": "需求概述",
                "content": requirement_data.get("detail", ""),
            },
            {
                "id": "block_2",
                "type": "table",
                "title": "文献分析结果",
                "columns": ["文档名", "标题", "标签", "关键词"],
                "rows": [
                    [
                        item["name"],
                        item["title"],
                        item["labels"],
                        "、".join(item["keywords"]),
                    ]
                    for item in analyses
                ],
            },
        ],
    }

    if related_labels:
        report["blocks"].append(
            {
                "id": "block_3",
                "type": "text",
                "title": "相关标签建议",
                "content": "；".join(
                    f"{label.top_label}: {', '.join(label.sub_label)}"
                    for label in related_labels
                ),
            }
        )

    return {
        "success": True,
        "report": report,
    }


def _analyze_document(document: RetrievedDocument) -> dict[str, Any]:
    analysis_result = analyze_with_openclaw(
        file_bytes=document.full_text.encode("utf-8"),
        file_name=document.name,
        doc_type=document.doc_type or "unknown",
    )

    return {
        "name": document.name,
        "title": document.title,
        "labels": str(analysis_result.get("labels") or "未标注"),
        "keywords": document.keywords,
    }


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
