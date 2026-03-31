import os
from langchain_openai import ChatOpenAI


def get_llm():
    return ChatOpenAI(
        model = os.getenv("MODEL"),
        base_url=os.getenv("BASE_URL"),
        api_key=os.getenv("API_KEY")
    )