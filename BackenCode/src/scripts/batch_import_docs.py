from __future__ import annotations

import argparse
import os
import re
from datetime import datetime
from pathlib import Path
import socket
import time
from typing import Any, Iterable
from urllib.parse import urlparse

import httpx
from dotenv import load_dotenv
from sqlalchemy import delete, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from src.db import get_session
from src.repositories.documents import (
    DocParsed,
    FileMetadata,
    FileResource,
    store_parsed_document,
)


DEFAULT_EXTENSIONS = {".pdf", ".doc", ".docx", ".txt", ".md"}
DEFAULT_SOURCE = "arxiv"
UNIQUE_SOURCE_TITLE_CONSTRAINT = "uq_file_metadata_source_title"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Batch parse files with MinerU and insert into doc_parsed/file_metadata/file_resource."
    )
    parser.add_argument("input_dir", help="Input directory containing files to ingest.")
    parser.add_argument(
        "--extensions",
        default=",".join(sorted(DEFAULT_EXTENSIONS)),
        help="Comma separated extensions to include, e.g. .pdf,.docx,.md",
    )
    parser.add_argument("--source", default=DEFAULT_SOURCE, help="Metadata source value.")
    parser.add_argument(
        "--mineru-base-url",
        default=None,
        help="Override MINERU_BASE_URL from .env, e.g. http://127.0.0.1:18081",
    )
    parser.add_argument(
        "--recursive",
        action="store_true",
        help="Recursively scan all sub-directories.",
    )
    parser.add_argument(
        "--refresh-existing",
        action="store_true",
        help="If path already exists, delete old rows in 3 tables then insert new parsed rows.",
    )
    parser.add_argument(
        "--mineru-timeout",
        type=float,
        default=float(os.getenv("MINERU_TIMEOUT", "180")),
        help="MinerU request timeout (seconds). Default: 180",
    )
    parser.add_argument(
        "--mineru-retries",
        type=int,
        default=2,
        help="Retry times when MinerU request fails. Total attempts = retries + 1.",
    )
    parser.add_argument(
        "--retry-wait",
        type=float,
        default=2.0,
        help="Seconds to wait between MinerU retries.",
    )
    parser.add_argument(
        "--trust-env-proxy",
        action="store_true",
        help="Allow httpx to read proxy env vars. Default is disabled for local MinerU stability.",
    )
    return parser.parse_args()


def normalize_extensions(raw: str) -> set[str]:
    exts = set()
    for item in raw.split(","):
        value = item.strip().lower()
        if not value:
            continue
        if not value.startswith("."):
            value = f".{value}"
        exts.add(value)
    return exts or set(DEFAULT_EXTENSIONS)


def list_input_files(input_dir: Path, recursive: bool, extensions: set[str]) -> list[Path]:
    iterator: Iterable[Path]
    if recursive:
        iterator = input_dir.rglob("*")
    else:
        iterator = input_dir.glob("*")
    files = [
        p
        for p in iterator
        if p.is_file() and p.suffix.lower() in extensions and not p.name.startswith("~$")
    ]
    return sorted(files)


def parse_with_mineru(
    *,
    file_bytes: bytes,
    file_name: str,
    mineru_base_url: str,
    timeout_seconds: float,
    retries: int,
    retry_wait: float,
    trust_env_proxy: bool,
) -> str:
    total_attempts = max(retries, 0) + 1
    timeout = httpx.Timeout(timeout_seconds)
    last_exc: Exception | None = None

    for attempt in range(1, total_attempts + 1):
        try:
            with httpx.Client(
                base_url=mineru_base_url,
                timeout=timeout,
                trust_env=trust_env_proxy,
            ) as client:
                response = client.post(
                    "/file_parse",
                    files={"files": (file_name, file_bytes)},
                )
                response.raise_for_status()
                data = response.json()

            results = data.get("results") or {}
            if not results:
                return ""
            first_key = next(iter(results))
            first = results.get(first_key) or {}
            return str(first.get("md_content") or "")
        except httpx.HTTPStatusError as exc:
            last_exc = exc
            status_code = exc.response.status_code if exc.response is not None else None
            is_retryable = status_code is None or status_code >= 500 or status_code == 429
            if attempt == total_attempts or not is_retryable:
                break
            print(
                f"  -> MinerU status={status_code}, retry {attempt}/{total_attempts} "
                f"in {retry_wait:.1f}s ..."
            )
            time.sleep(max(retry_wait, 0))
        except (httpx.RequestError, ValueError) as exc:
            last_exc = exc
            if attempt == total_attempts:
                break
            print(
                f"  -> MinerU request failed ({type(exc).__name__}), "
                f"retry {attempt}/{total_attempts} in {retry_wait:.1f}s ..."
            )
            time.sleep(max(retry_wait, 0))

    detail = f"{type(last_exc).__name__}: {last_exc}" if last_exc else "unknown error"
    raise RuntimeError(
        f"MinerU parse failed after {total_attempts} attempts for file: {file_name}. "
        f"Last error: {detail}"
    ) from last_exc


def check_mineru_reachable(mineru_base_url: str, timeout_seconds: float) -> tuple[bool, str]:
    try:
        parsed = urlparse(mineru_base_url)
        host = parsed.hostname
        if not host:
            return False, f"invalid MINERU_BASE_URL: {mineru_base_url}"
        port = parsed.port or (443 if parsed.scheme == "https" else 80)
        sock = socket.create_connection((host, port), timeout=timeout_seconds)
        sock.close()
        return True, f"reachable: {host}:{port}"
    except Exception as exc:
        return False, f"unreachable: {mineru_base_url} ({type(exc).__name__}: {exc})"


def _find_file_resource_ids_by_path(session: Session, path_str: str) -> list[int]:
    rows = session.execute(
        select(FileResource.id).where(FileResource.path == path_str)
    ).scalars()
    return [int(x) for x in rows]


def _delete_existing_documents(session: Session, *, file_resource_ids: list[int], path_str: str) -> None:
    if not file_resource_ids:
        return
    session.execute(delete(DocParsed).where(DocParsed.doc_id.in_(file_resource_ids)))
    session.execute(delete(FileMetadata).where(FileMetadata.file_id.in_(file_resource_ids)))
    session.execute(delete(FileResource).where(FileResource.path == path_str))


def _is_source_title_unique_violation(exc: IntegrityError) -> bool:
    orig = getattr(exc, "orig", None)
    pgcode = getattr(orig, "pgcode", None) or getattr(orig, "sqlstate", None)
    if pgcode != "23505":
        return False
    diag = getattr(orig, "diag", None)
    constraint_name = getattr(diag, "constraint_name", None)
    if constraint_name == UNIQUE_SOURCE_TITLE_CONSTRAINT:
        return True
    return UNIQUE_SOURCE_TITLE_CONSTRAINT in str(exc).lower()


def _find_existing_metadata_by_source_title(source: str, title: str) -> tuple[int, int] | None:
    with get_session() as session:
        row = session.execute(
            select(FileMetadata.id, FileMetadata.file_id)
            .where(FileMetadata.source == source, FileMetadata.title == title)
            .limit(1)
        ).first()
        if row is None:
            return None
        metadata_id, file_id = row
        return int(file_id), int(metadata_id)


def build_structure_info(full_text: str) -> dict[str, Any]:
    headings: list[dict[str, Any]] = []
    for line in full_text.splitlines():
        stripped = line.strip()
        if not stripped.startswith("#"):
            continue
        level = len(stripped) - len(stripped.lstrip("#"))
        title = stripped[level:].strip()
        if title:
            headings.append({"level": level, "title": title})
    return {"headings": headings}


def extract_metadata(
    *, full_text: str, file_name: str, source: str
) -> dict[str, Any]:
    lines = [line.strip() for line in full_text.splitlines()]
    non_empty_lines = [line for line in lines if line]

    title = extract_title(non_empty_lines, file_name)
    abstract = extract_abstract(lines)
    keywords = extract_keywords(lines)
    authors, institutions = extract_authors_and_institutions(lines, title)
    publish_year = extract_publish_year(full_text, file_name)
    language = detect_language(full_text)

    return {
        "source": source,
        "title": title,
        "authors": authors,
        "institutions": institutions,
        "publish_year": publish_year,
        "keywords": keywords,
        "abstract": abstract,
        "language": language,
    }


def _normalize_heading(line: str) -> str:
    return line.lstrip("#").strip()


def _is_generic_section_title(line: str) -> bool:
    lowered = line.lower().strip().strip(":")
    generic = {
        "abstract",
        "keywords",
        "index terms",
        "introduction",
        "references",
        "appendix",
        "acknowledgements",
        "acknowledgments",
    }
    if lowered in generic:
        return True
    return bool(
        re.match(
            r"^(?:\d+(?:\.\d+)*)\s+(abstract|keywords|index terms|introduction|references|appendix)$",
            lowered,
        )
    )


def is_probable_author_line(line: str) -> bool:
    text = _normalize_heading(line)
    if not text or len(text) > 255:
        return False
    if looks_like_institution(text):
        return False
    if "@" in text:
        return True
    if re.search(r"\b(et al\.?)\b", text.lower()):
        return True

    english_name_hits = len(
        re.findall(
            r"\b[A-Z][a-z]+(?:[-'][A-Z][a-z]+)?\s+[A-Z][a-z]+(?:[-'][A-Z][a-z]+)?\b",
            text,
        )
    )
    chinese_name_hits = len(re.findall(r"[\u4e00-\u9fff]{2,4}", text))
    affiliation_marks = sum(text.count(ch) for ch in ("†", "‡", "*", "§", "¶"))
    connector_hits = len(
        re.findall(r"\b(of|for|with|in|on|via|towards|from|to|using|the|a|an)\b", text.lower())
    )
    comma_count = text.count(",")

    if english_name_hits >= 3 and affiliation_marks > 0:
        return True
    # Common author format: "A B, C D, E F"
    if english_name_hits >= 2 and comma_count >= 1 and connector_hits <= 1 and len(text.split()) <= 30:
        return True
    # Fallback for plain name lists without commas/symbols.
    if english_name_hits >= 3 and comma_count == 0 and affiliation_marks == 0:
        words = re.findall(r"[A-Za-z]+", text.lower())
        title_hints = {
            "language",
            "model",
            "models",
            "retrieval",
            "reasoning",
            "tool",
            "tools",
            "survey",
            "towards",
            "via",
            "introduction",
            "abstract",
            "benchmark",
            "agent",
            "agents",
            "research",
            "learning",
            "knowledge",
            "intensive",
        }
        hint_hits = sum(1 for w in words if w in title_hints)
        if hint_hits <= 1 and len(words) <= 20:
            return True
    if chinese_name_hits >= 3 and connector_hits <= 1:
        return True
    return False


def is_probable_title_line(line: str) -> bool:
    text = _normalize_heading(line)
    if not (5 <= len(text) <= 256):
        return False
    if _is_generic_section_title(text):
        return False
    if looks_like_institution(text):
        return False
    if is_probable_author_line(text):
        return False
    if "@" in text:
        return False
    return True


def extract_title(non_empty_lines: list[str], file_name: str) -> str:
    heading_candidates = [_normalize_heading(line) for line in non_empty_lines[:60] if line.startswith("#")]
    for candidate in heading_candidates:
        if is_probable_title_line(candidate):
            return candidate

    for line in non_empty_lines[:30]:
        if is_probable_title_line(line):
            return _normalize_heading(line)

    for line in non_empty_lines[:30]:
        candidate = _normalize_heading(line)
        if 3 <= len(candidate) <= 256 and not _is_generic_section_title(candidate):
            return candidate

    return Path(file_name).stem[:256]


def extract_abstract(lines: list[str]) -> str | None:
    marker_indices = []
    for idx, line in enumerate(lines):
        normalized = line.lower().strip().strip(":")
        if normalized in {"# abstract", "abstract", "摘要", "# 摘要"}:
            marker_indices.append(idx)
    for idx in marker_indices:
        chunks: list[str] = []
        for line in lines[idx + 1 :]:
            stripped = line.strip()
            if not stripped:
                if chunks:
                    break
                continue
            if stripped.startswith("#"):
                break
            chunks.append(stripped)
        if chunks:
            return " ".join(chunks)[:10000]
    return None


def extract_keywords(lines: list[str]) -> list[str]:
    marker_regex = re.compile(
        r"^\s*(?:#+\s*)?(?:\*\*|__)?(keywords?|key words|index terms|关键词)"
        r"(?:\*\*|__)?\s*(?:[:：\-—]\s*)?(.*)\s*$",
        re.IGNORECASE,
    )

    max_scan = min(len(lines), 400)
    for idx in range(max_scan):
        line = lines[idx].strip()
        if not line:
            continue

        match = marker_regex.match(line)
        if not match:
            continue

        tail = match.group(2).strip()
        if not tail:
            for next_idx in range(idx + 1, min(idx + 6, max_scan)):
                candidate = lines[next_idx].strip()
                if not candidate:
                    continue
                if candidate.startswith("#"):
                    break
                tail = candidate
                break

        keywords = _split_keywords_text(tail)
        if keywords:
            return keywords[:20]

    return []


def _split_keywords_text(text: str) -> list[str]:
    if not text:
        return []

    normalized = text.strip()
    normalized = re.sub(r"^(?:\*\*|__)\s*", "", normalized)
    normalized = re.sub(
        r"^(keywords?|key words|index terms|关键词)\s*(?:[:：\-—]\s*)?",
        "",
        normalized,
        flags=re.IGNORECASE,
    )
    normalized = normalized.strip(" \t:：-—–;；,.。")
    if not normalized:
        return []

    raw_parts = re.split(r"[;,，、；|/]|(?:\s+-\s+)|(?:\s+•\s+)|(?:\s+\|\s+)", normalized)
    cleaned: list[str] = []
    for part in raw_parts:
        value = part.strip(" \t:：-—–;；,.。")
        value = re.sub(r"^[^\w\u4e00-\u9fff]+", "", value)
        if not value:
            continue
        if len(value.split()) > 12 and not re.search(r"[,;，、|/]", normalized):
            return []
        if value.lower() in {"keywords", "keyword", "index terms", "key words", "关键词"}:
            continue
        cleaned.append(value)

    deduped: list[str] = []
    seen: set[str] = set()
    for kw in cleaned:
        key = kw.casefold()
        if key in seen:
            continue
        seen.add(key)
        deduped.append(kw)
    return deduped


def extract_authors_and_institutions(lines: list[str], title: str) -> tuple[str | None, str | None]:
    title_norm = _normalize_heading(title)
    start = 0
    if title_norm:
        for i, line in enumerate(lines):
            if title_norm and title_norm in _normalize_heading(line):
                start = i
                break

    window = [line.strip() for line in lines[start + 1 : start + 25] if line.strip()]
    authors: str | None = None
    institutions: list[str] = []

    for line in window:
        normalized = _normalize_heading(line)
        lowered = line.lower()
        if "abstract" in lowered or line.startswith("#"):
            break
        if authors is None and looks_like_authors(normalized):
            authors = normalized[:255]
            continue
        if looks_like_institution(normalized):
            institutions.append(normalized)

    institutions_text = "; ".join(dict.fromkeys(institutions))[:255] if institutions else None
    return authors, institutions_text


def looks_like_authors(line: str) -> bool:
    text = _normalize_heading(line)
    if len(text) > 255:
        return False
    if looks_like_institution(text):
        return False
    if "@" in text:
        return False
    if is_probable_author_line(text):
        return True
    english_name_hits = len(re.findall(r"[A-Z][a-z]+ [A-Z][a-z]+", text))
    chinese_name_hits = len(re.findall(r"[\u4e00-\u9fff]{2,4}", text))
    return english_name_hits >= 2 or chinese_name_hits >= 2


def looks_like_institution(line: str) -> bool:
    tokens = [
        "university",
        "college",
        "institute",
        "laboratory",
        "lab",
        "school",
        "大学",
        "学院",
        "研究所",
        "实验室",
        "研究院",
    ]
    lowered = line.lower()
    return any(token in lowered or token in line for token in tokens)


def extract_publish_year(full_text: str, file_name: str) -> datetime | None:
    candidates = re.findall(r"\b(19\d{2}|20\d{2}|21\d{2})\b", file_name + "\n" + full_text[:8000])
    valid = sorted({int(x) for x in candidates if 1900 <= int(x) <= 2100})
    if not valid:
        return None
    return datetime(valid[-1], 1, 1)


def detect_language(full_text: str) -> str:
    sample = full_text[:3000]
    if not sample:
        return "unknown"
    zh_chars = len(re.findall(r"[\u4e00-\u9fff]", sample))
    ascii_letters = len(re.findall(r"[A-Za-z]", sample))
    if zh_chars > ascii_letters:
        return "zh"
    return "en"


def main() -> None:
    load_dotenv()
    args = parse_args()

    input_dir = Path(args.input_dir).expanduser().resolve()
    if not input_dir.exists() or not input_dir.is_dir():
        raise SystemExit(f"Input directory not found: {input_dir}")

    mineru_base_url = args.mineru_base_url or os.getenv("MINERU_BASE_URL")
    if not mineru_base_url:
        raise SystemExit("MINERU_BASE_URL is missing. Please configure .env first.")
    mineru_base_url = mineru_base_url.strip()

    ok, detail = check_mineru_reachable(
        mineru_base_url=mineru_base_url,
        timeout_seconds=min(args.mineru_timeout, 5),
    )
    if not ok:
        print(f"MinerU precheck failed: {detail}")
        print(
            "Please make sure MinerU service is running and listening on the target port. "
            "If using SSH tunnel, start it before import."
        )
        return

    extensions = normalize_extensions(args.extensions)
    files = list_input_files(input_dir, args.recursive, extensions)
    if not files:
        print(f"No files found in {input_dir} with extensions: {sorted(extensions)}")
        return

    print(f"Found {len(files)} files. Start ingesting...")
    success = 0
    duplicate_skipped = 0
    failed = 0
    refreshed = 0
    interrupted = False

    for idx, path in enumerate(files, start=1):
        path_str = str(path)
        print(f"[{idx}/{len(files)}] Processing: {path_str}")
        metadata: dict[str, Any] | None = None
        try:
            file_bytes = path.read_bytes()
            full_text = parse_with_mineru(
                file_bytes=file_bytes,
                file_name=path.name,
                mineru_base_url=mineru_base_url,
                timeout_seconds=args.mineru_timeout,
                retries=args.mineru_retries,
                retry_wait=args.retry_wait,
                trust_env_proxy=args.trust_env_proxy,
            )
            metadata = extract_metadata(
                full_text=full_text,
                file_name=path.name,
                source=args.source,
            )
            structure_info = build_structure_info(full_text)

            inserted_ids = None
            with get_session() as session:
                if args.refresh_existing:
                    existing_ids = _find_file_resource_ids_by_path(session, path_str)
                    if existing_ids:
                        _delete_existing_documents(
                            session,
                            file_resource_ids=existing_ids,
                            path_str=path_str,
                        )
                        refreshed += 1
                        print(
                            f"  -> refreshed old records "
                            f"(deleted file_resource ids={existing_ids})"
                        )
                inserted_ids = store_parsed_document(
                    session,
                    file_path=path_str,
                    file_name=path.name,
                    full_text=full_text,
                    structure_info=structure_info,
                    metadata=metadata,
                )
            # Count as success only after the session exits cleanly (commit succeeded).
            if inserted_ids is not None:
                print(
                    "  -> inserted "
                    f"(file_resource={inserted_ids.file_resource_id}, "
                    f"file_metadata={inserted_ids.file_metadata_id}, "
                    f"doc_parsed={inserted_ids.doc_parsed_id})"
                )
                success += 1
        except KeyboardInterrupt:
            interrupted = True
            print("Interrupted by user. Stopping batch import gracefully.")
            break
        except IntegrityError as exc:
            if _is_source_title_unique_violation(exc) and metadata is not None:
                duplicate_skipped += 1
                source = str(metadata.get("source") or args.source)
                title = str(metadata.get("title") or path.name)
                existing = _find_existing_metadata_by_source_title(source, title)
                if existing is not None:
                    existing_file_id, existing_metadata_id = existing
                    print(
                        "  -> skipped duplicate: title+source detected "
                        f"(title={title!r}, source={source!r}, "
                        f"existing_file_id={existing_file_id}, "
                        f"existing_metadata_id={existing_metadata_id})"
                    )
                else:
                    print(
                        "  -> skipped duplicate: title+source detected "
                        f"(title={title!r}, source={source!r})"
                    )
                continue
            failed += 1
            print(f"  -> failed (db): {exc}")
        except Exception as exc:
            failed += 1
            print(f"  -> failed: {exc}")

    if interrupted:
        print(
            "Stopped. "
            f"success={success}, refreshed={refreshed}, "
            f"duplicate_skipped={duplicate_skipped}, failed={failed}, total={len(files)}"
        )
        return

    print(
        "Done. "
        f"success={success}, refreshed={refreshed}, "
        f"duplicate_skipped={duplicate_skipped}, failed={failed}, total={len(files)}"
    )


if __name__ == "__main__":
    main()
