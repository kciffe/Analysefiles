from openai import OpenAI,pydantic_function_tool
from ..db import get_session

def search_paragraph(
    doc_id: int,
    section_title: str,
):
    with get_session() as session:
        pass