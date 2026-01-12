from typing import Any

from pydantic import BaseModel


class ParseResult(BaseModel):
    full_text: str
    structure_info: dict[str, Any]
    metadata: dict[str, Any] | None = None


class ParseService(BaseModel):
    def run(self, *, file_bytes: bytes, file_name: str, doc_type: str) -> ParseResult:
        return ParseResult(full_text="123", structure_info={"name": "test"}, metadata={"metadata": "yes"})
