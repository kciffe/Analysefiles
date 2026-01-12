from typing import Any

from pydantic import BaseModel


class ParseResponse(BaseModel):
    structure_info: dict[str, Any]
