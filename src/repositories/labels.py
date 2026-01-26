from typing import List
from sqlalchemy import String, select
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.dialects.postgresql import JSONB

from .base import Base
from ..db import get_session

class Labels(Base):

    __tablename__ = "labels"

    id: Mapped[int] = mapped_column(primary_key=True)
    top_label: Mapped[str] = mapped_column(String(128), nullable=False)
    sub_label: Mapped[List[str]] = mapped_column(JSONB, nullable=False)


def select_labels() -> List[Labels]:
    with get_session() as db_session:
        stmt = select(Labels)
        result = db_session.execute(stmt)
        return result.scalars().all()
