import os
from langchain_openai import ChatOpenAI
from dotenv import load_dotenv

from ...tools import TOOLS
load_dotenv()


def _base_llm():
    return ChatOpenAI(
        model=os.getenv("MODEL"),
        base_url=os.getenv("BASE_URL"),
        api_key=os.getenv("DEEPSEEK_API_KEY"),
    )


def get_llm():
    return _base_llm().bind_tools(TOOLS)


def get_llm_without_tools():
    return _base_llm()
