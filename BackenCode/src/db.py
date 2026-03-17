from __future__ import annotations

from contextlib import contextmanager
from typing import Iterator

from sqlalchemy import create_engine
from sqlalchemy.engine import Engine
from sqlalchemy.orm import Session, sessionmaker


@contextmanager
def get_session() -> Iterator[Session]:
    session = _get_sessionmaker()()
    try:
        yield session
        session.commit()
    except Exception:
        session.rollback()
        raise
    finally:
        session.close()

DATABASE_URL_SYNC = "postgresql://postgres:123456@localhost:5432/deep_research"

_engine: Engine = create_engine(
    DATABASE_URL_SYNC,
    pool_size=10,
    max_overflow=20,
    echo=True,
)

_sessionmaker: sessionmaker | None = None


def _get_sessionmaker() -> sessionmaker:
    global _engine
    global _sessionmaker
    if _sessionmaker is None:
        _sessionmaker = sessionmaker(
            bind=_engine,
            autoflush=False,
            autocommit=False,
            expire_on_commit=False,
        )
    return _sessionmaker

