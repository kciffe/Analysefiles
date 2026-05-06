import os
from langchain_openai import ChatOpenAI
from langchain.chat_models import init_chat_model
from dotenv import load_dotenv

from ...tools import TOOLS
load_dotenv()


def _base_llm():
    return init_chat_model(
        model=os.getenv("MODEL"),
        base_url=os.getenv("BASE_URL"),
        api_key=os.getenv("DEEPSEEK_API_KEY"),
    )


def get_llm():
    """
    用于需要工具调用的 LangGraph 节点
    """
    return _base_llm().bind_tools(TOOLS)


def get_llm_without_tools():
    """
    用于不需要工具调用的 LangGraph 节点
    """
    return _base_llm()
