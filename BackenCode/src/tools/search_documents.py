import os
from typing import Literal
import json
from openai import pydantic_function_tool, OpenAI
from pydantic import BaseModel, Field
from ..repositories.documents import search_documents_by_keywords
from ..db import get_session

#TODO: 规范search_documents输出结果为字符串
#description丰富
#检索工具返回格式：题目、作者、摘要、发布时间、论文目录结构
#中间工具调用过程持久化
#langgraph实现控制循环
def search_documents(
    keywords: list[str] | None = None,
    doc_types: list[str] | None = None,
    start_date: str | None = None,
    end_date: str | None = None,
    limit: int = 128,
):
    for keyword in keywords:
        if keyword not in ["LLM Agent", "Tool use"]:
            return f"{keyword} is not in [LLM Agent, Tool use]"
    with get_session() as session:
        return str([item.__dict__ for item in search_documents_by_keywords(
            session,
            keywords=keywords,
            doc_types=doc_types,
            start_date=start_date,
            end_date=end_date,
            limit=limit,
        )])

class SearchDocumentsRequest(BaseModel):
    keywords: list[str] | None = Field(None, description="搜索的关键词")
    doc_types: list[str] | None = Field(Literal["LLM Agent", "Tool use"], description="文档类型,如ACL、arxiv等")
    start_date: str | None = Field(None, description="文档发布的最早时间")
    end_date: str | None = Field(None, description="文档发布的最晚时间")
    limit: int = Field(128, description="返回的文档数量上限")


search_docs = pydantic_function_tool(
    SearchDocumentsRequest,
    name="search_docs",
    description="搜索文档工具，依据需求描述，返回满足条件的文档信息",
)

print(search_docs)

tool_kits = {
    "search_docs": search_documents,
}

client = OpenAI(
    base_url="https://api.deepseek.com",
    api_key="sk-b4ea87f44560461c930519e78c7d9978"
)
model = "deepseek-chat"

messages = [
            {
                "role": "system",
                "content": "You are a helpful assistant. 关键词跟Agent有关的只有2个 —— LLM Agent和Tool use",
            },
            {
                "role": "user",
                "content": "随便搜两篇arXiv预印本文档出来, 跟Agent有关就行。",
            },
        ]


terminate = False
while not terminate:
    completion = client.chat.completions.create(
        model=model,
        messages=messages,
        tools=[search_docs]
    )


    print(completion.choices[0])
    if completion.choices[0].finish_reason == "tool_calls":
        tool_call = completion.choices[0].message.tool_calls[0]
        messages.append(
            {
                "role": "assistant",
                "content": completion.choices[0].message.content,
                "tool_calls": [
                    {
                        "id": tool_call.id,
                        "function": tool_call.function,
                        "type": "function",
                    }
                ]
            }
        )
        print(completion.choices[0])
        tool_name = tool_call.function.name
        args = json.loads(tool_call.function.arguments)
        response = tool_kits[tool_name](**args)

        messages.append(
            {
                "role": "tool",
                "content": response,
                "tool_call_id": tool_call.id,
                "function": {
                    "name": tool_name,
                    "arguments": json.dumps(args, ensure_ascii=False),
                },
            }
        )

        print(f"[tool result] {response}")

    else:
        print(f"[final answer] {completion.choices[0].message.content}")
        terminate = True
