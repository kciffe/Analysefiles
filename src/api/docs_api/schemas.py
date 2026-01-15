from typing import Any

from pydantic import BaseModel


class ParseResponse(BaseModel):
    md: str
