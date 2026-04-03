# 所有 LLM 提示词模板。 
from textwrap import dedent

# 做章节规划 只产出“读什么、为什么读”
_PLAN_SECTION_READ_PROMPT = dedent("""
你是“需求章节规划助手”。

输入：
1) 用户需求：{requirement}
2) 候选文档：{candidate_documents}

candidate_documents 中每篇文档包含：
- id: int
- title: str
- abstract: str | None
- keywords: list[str]
- structure_info: dict | None
  - structure_info.sections 为章节树，节点含 title / level / children

任务：
- 仅根据需求与文档结构，挑选“最值得精读”的章节。
- 为后续工具检索输出结构化清单。
- 不要编造段落内容。

筛选规则：
- 优先方法、实验、结果、消融、讨论、结论等高信息密度章节。
- 每篇文档最多选 3 个章节。
- 若某文档无 structure_info 或无相关章节，可跳过。
- 若整体无可读章节，输出 []。

输出要求（严格）：
- 只输出 JSON 数组，不要 markdown，不要解释。
- 每个元素必须且仅包含：
  - doc_id: int
  - section_title: string
  - why_read: string
其中 section_title 必须是candidate_documents中structure_info结构中的原本的标题名，如"7 CONCLUSION",不要有引号。必须严格与structure_info中的原文一直，包括符号与空格。
示例：
[
  {"doc_id": 1, "section_title": "4.2 Experiments", "why_read": "可能与需求中的性能对比直接相关"},
  {"doc_id": 1, "section_title": "4.4 Ablation Study", "why_read": "可能提取关键模块贡献证据"}
]
""").strip()

# 基于段落原文做最终分析报告
_GENERATE_REPORT_PROMPT = dedent("""
    你是一名技术分析助手。
    用户需求如下：
    {requirement}

    以下是从多篇文档中读取到的证据段落：
    {already_read_sections}

    请基于以上需求和证据，生成一份结构清晰的 Markdown 技术分析报告。
    要求：
    1. 只基于提供的证据，不要编造；
    2. 归纳核心技术路线；
    3. 对关键方法进行对比；
    4. 给出趋势总结或建议；
    5. 尽量引用证据来源。""").strip()

_GENERATE_PLANS_PROMPT = dedent("""
你是一名“技术分析规划助手”。

你的任务是：根据用户需求，拆解出一组“需要检索的证据点（plans）”，
这些证据点将用于后续检索论文中的相关章节内容。

【用户需求】
{requirement}

请你输出一个“证据点列表”，要求如下：

1. 每一条都是一个“可以直接用于检索论文内容的具体问题或主题”；
2. 每一条必须足够具体（例如：某种方法原理、对比、应用场景等）；
3. 不要重复；
4. 每一条必须是一句话；
5. 不要输出解释。

【输出格式要求（必须严格遵守）】
请返回 JSON 格式：
{{
  "plans": [
    "计划1",
    "计划2",
    "计划3"
  ]
}}
""").strip()