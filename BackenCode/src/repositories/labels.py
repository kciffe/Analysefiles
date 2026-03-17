from typing import List

from sqlalchemy import String, select
from sqlalchemy.orm import Mapped, Session, mapped_column
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
        return select_labels_by_filters(db_session)


def select_labels_by_filters(
    db_session: Session,
    *,
    top_label: str | None = None,
    keyword: str | None = None,
) -> List[Labels]:
    stmt = select(Labels)

    if top_label:
        stmt = stmt.where(Labels.top_label.ilike(f"%{top_label}%"))

    if keyword:
        stmt = stmt.where(Labels.sub_label.cast(String).ilike(f"%{keyword}%"))

    result = db_session.execute(stmt.order_by(Labels.id.asc()))
    return result.scalars().all()
