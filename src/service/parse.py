from typing import Any, TypedDict
import httpx
from pydantic import BaseModel

class MarkdownContent(TypedDict):
    md_content: str

class MinerUParse(BaseModel):
    backend: str
    version: str
    results: dict[str, MarkdownContent]

class ParseResult(BaseModel):
    full_text: str
    structure_info: dict[str, Any]
    metadata: dict[str, Any] | None = None

class ParseService(BaseModel):
    def run(self, *, file_bytes: bytes, file_name: str, doc_type: str) -> ParseResult:
        file_name_splits = file_name.split(".")
        with httpx.Client(base_url="http://localhost:8001") as client:
            response = client.post(
                "/file_parse",
                files={
                    "files": file_bytes
                },
                timeout=1000,
            )
            resp = MinerUParse.model_validate(response.json())

            # Get the first index
            first_key = next(iter(resp.results))
            full_text = resp.results[first_key]["md_content"]
            print(full_text)
        return ParseResult(full_text=full_text, structure_info={"name": "yh"})