import os
import json
from openai import  OpenAI
from .search_paragraph import search_paragraph_tool,search_paragraph
from .registry import TOOL_FUNCTIONS,TOOLS

client = OpenAI(
    base_url="https://api.deepseek.com",
    api_key="sk-b4ea87f44560461c930519e78c7d9978"
)
model = "deepseek-chat"

messages = [
    {
        "role": "system",
        "content": "你是一个助手，你需要根据用户输入的搜索内容，返回一个满足搜索条件的文档内容。"
    },
    {
        "role": "user",
        "content": "文档id为1，章节标题为'方法'的内容是什么？"
    }
]

terminate = False
while not terminate:
    completion = client.chat.completions.create(
        model=model,
        messages=messages,
        tools=TOOLS,
        parallel_tool_calls=True
    )
    print(completion.choices[0].message.content)
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
        response = TOOL_FUNCTIONS[tool_name](**args)

        messages.append(
            {
                "role": "tool",
                "content": response,
                "tool_call_id": tool_call.id,
                "function":{
                    "name":tool_name,
                    "arguments":json.dumps(args,ensure_ascii=False)
                }
            }
        )
        print(f"[tool result] {response}")
    else:
        print(f"[final response]{completion.choices[0].message.content}")
        terminate = True

