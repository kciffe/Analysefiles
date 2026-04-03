import os
from langchain_openai import ChatOpenAI
from dotenv import load_dotenv

from ..tools import TOOLS
load_dotenv()
def get_llm():
    return ChatOpenAI(
        model = os.getenv("MODEL"),
        base_url=os.getenv("BASE_URL"),
        api_key=os.getenv("DEEPSEEK_API_KEY")
    ).bind_tools(TOOLS)