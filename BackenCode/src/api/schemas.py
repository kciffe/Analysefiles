from typing import Generic, TypeVar
from pydantic import BaseModel

T = TypeVar("_T")

class ResponseModel(BaseModel, Generic[T]):
    code: int
    msg: str | None = None
    data: T