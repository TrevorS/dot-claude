# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "PyMuPDF",
#     "ebooklib",
#     "beautifulsoup4",
#     "mobi",
#     "rank-bm25",
#     "click",
# ]
# ///
"""
Book Reader - Read and search digital books (PDF, EPUB, MOBI, TXT).

Usage:
    uvx book_reader.py info <file>
    uvx book_reader.py toc <file>
    uvx book_reader.py read <file> [--chapter N] [--page N] [--start N --length N]
    uvx book_reader.py search <file> <query>
    uvx book_reader.py extract <file>
"""
from __future__ import annotations

import hashlib
import json
import re
from abc import ABC, abstractmethod
from dataclasses import dataclass, field, asdict
from pathlib import Path
from typing import Protocol, runtime_checkable

import click

# =============================================================================
# Data Models
# =============================================================================


@dataclass
class Page:
    """A page of content with its number."""
    number: int
    content: str


@dataclass
class Chapter:
    """A chapter containing pages."""
    number: int
    title: str
    pages: list[Page] = field(default_factory=list)

    @property
    def content(self) -> str:
        """Get all content in this chapter."""
        return "\n\n".join(p.content for p in self.pages)


@dataclass
class Book:
    """A complete book with metadata and content."""
    path: Path
    title: str
    author: str | None
    chapters: list[Chapter] = field(default_factory=list)
    format: str = ""

    @property
    def page_count(self) -> int:
        """Total number of pages."""
        return sum(len(ch.pages) for ch in self.chapters)

    @property
    def all_pages(self) -> list[Page]:
        """Get all pages across all chapters."""
        pages = []
        for ch in self.chapters:
            pages.extend(ch.pages)
        return pages

    def get_page(self, n: int) -> Page | None:
        """Get a specific page by number."""
        for page in self.all_pages:
            if page.number == n:
                return page
        return None

    def get_chapter(self, n: int) -> Chapter | None:
        """Get a specific chapter by number."""
        for ch in self.chapters:
            if ch.number == n:
                return ch
        return None


# =============================================================================
# Extractor Protocol
# =============================================================================


@runtime_checkable
class Extractor(Protocol):
    """Protocol for book format extractors."""

    extensions: list[str]

    def can_handle(self, path: Path) -> bool:
        """Check if this extractor can handle the file."""
        ...

    def extract(self, path: Path) -> Book:
        """Extract the full book."""
        ...

    def get_metadata(self, path: Path) -> dict:
        """Get just metadata (faster than full extraction)."""
        ...


# =============================================================================
# PDF Extractor
# =============================================================================


class PDFExtractor:
    """Extract content from PDF files using PyMuPDF."""

    extensions = [".pdf"]

    def can_handle(self, path: Path) -> bool:
        return path.suffix.lower() in self.extensions

    def extract(self, path: Path) -> Book:
        import fitz  # PyMuPDF

        doc = fitz.open(str(path))

        # Get metadata
        meta = doc.metadata or {}
        title = meta.get("title") or path.stem
        author = meta.get("author")

        # Extract pages
        pages = []
        for i, page in enumerate(doc):
            text = page.get_text()
            if text.strip():
                pages.append(Page(number=i + 1, content=text))

        # Try to detect chapters from TOC
        toc = doc.get_toc()
        chapters = self._pages_to_chapters(pages, toc)

        doc.close()

        return Book(
            path=path,
            title=title,
            author=author,
            chapters=chapters,
            format="pdf"
        )

    def _pages_to_chapters(self, pages: list[Page], toc: list) -> list[Chapter]:
        """Convert pages to chapters using TOC if available."""
        if not toc:
            # No TOC - treat entire book as one chapter
            return [Chapter(number=1, title="Full Text", pages=pages)]

        chapters = []
        toc_entries = [(title, page_num) for level, title, page_num in toc if level == 1]

        if not toc_entries:
            return [Chapter(number=1, title="Full Text", pages=pages)]

        for i, (title, start_page) in enumerate(toc_entries):
            end_page = toc_entries[i + 1][1] if i + 1 < len(toc_entries) else float('inf')
            chapter_pages = [p for p in pages if start_page <= p.number < end_page]
            chapters.append(Chapter(
                number=i + 1,
                title=title,
                pages=chapter_pages
            ))

        # Handle pages before first chapter
        first_chapter_page = toc_entries[0][1] if toc_entries else 1
        front_matter = [p for p in pages if p.number < first_chapter_page]
        if front_matter:
            chapters.insert(0, Chapter(number=0, title="Front Matter", pages=front_matter))

        return chapters

    def get_metadata(self, path: Path) -> dict:
        import fitz

        doc = fitz.open(str(path))
        meta = doc.metadata or {}
        page_count = doc.page_count
        toc = doc.get_toc()
        doc.close()

        return {
            "title": meta.get("title") or path.stem,
            "author": meta.get("author"),
            "format": "pdf",
            "page_count": page_count,
            "chapter_count": len([t for t in toc if t[0] == 1]) or 1,
        }


# =============================================================================
# EPUB Extractor
# =============================================================================


class EPUBExtractor:
    """Extract content from EPUB files using ebooklib."""

    extensions = [".epub"]

    def can_handle(self, path: Path) -> bool:
        return path.suffix.lower() in self.extensions

    def extract(self, path: Path) -> Book:
        import ebooklib
        from ebooklib import epub
        from bs4 import BeautifulSoup

        book = epub.read_epub(str(path))

        # Get metadata
        title = book.get_metadata('DC', 'title')
        title = title[0][0] if title else path.stem
        author = book.get_metadata('DC', 'creator')
        author = author[0][0] if author else None

        # Extract chapters from spine
        chapters = []
        page_num = 1

        for i, item in enumerate(book.get_items_of_type(ebooklib.ITEM_DOCUMENT)):
            content = item.get_content()
            soup = BeautifulSoup(content, 'html.parser')

            # Get chapter title
            title_tag = soup.find(['h1', 'h2', 'h3', 'title'])
            chapter_title = title_tag.get_text().strip() if title_tag else f"Chapter {i + 1}"

            # Get text content
            text = soup.get_text(separator='\n\n')
            text = re.sub(r'\n{3,}', '\n\n', text).strip()

            if text:
                # Split into pages (approximate, ~3000 chars per page)
                page_size = 3000
                pages = []
                for j in range(0, len(text), page_size):
                    chunk = text[j:j + page_size]
                    pages.append(Page(number=page_num, content=chunk))
                    page_num += 1

                chapters.append(Chapter(
                    number=i + 1,
                    title=chapter_title,
                    pages=pages
                ))

        return Book(
            path=path,
            title=title,
            author=author,
            chapters=chapters,
            format="epub"
        )

    def get_metadata(self, path: Path) -> dict:
        import ebooklib
        from ebooklib import epub

        book = epub.read_epub(str(path))

        title = book.get_metadata('DC', 'title')
        title = title[0][0] if title else path.stem
        author = book.get_metadata('DC', 'creator')
        author = author[0][0] if author else None

        chapter_count = len(list(book.get_items_of_type(ebooklib.ITEM_DOCUMENT)))

        return {
            "title": title,
            "author": author,
            "format": "epub",
            "chapter_count": chapter_count,
        }


# =============================================================================
# MOBI Extractor
# =============================================================================


class MOBIExtractor:
    """Extract content from MOBI files."""

    extensions = [".mobi", ".azw", ".azw3"]

    def can_handle(self, path: Path) -> bool:
        return path.suffix.lower() in self.extensions

    def extract(self, path: Path) -> Book:
        import tempfile
        import mobi
        from bs4 import BeautifulSoup

        # mobi extracts to a temp directory
        with tempfile.TemporaryDirectory() as tmpdir:
            tmppath, extracted = mobi.extract(str(path))

            # Find the HTML file
            html_file = None
            for f in Path(tmppath).rglob("*.html"):
                html_file = f
                break

            if not html_file:
                # Fallback to any text content
                for f in Path(tmppath).rglob("*.htm*"):
                    html_file = f
                    break

            if not html_file:
                return Book(
                    path=path,
                    title=path.stem,
                    author=None,
                    chapters=[Chapter(number=1, title="Content", pages=[])],
                    format="mobi"
                )

            with open(html_file, 'r', encoding='utf-8', errors='ignore') as f:
                content = f.read()

            soup = BeautifulSoup(content, 'html.parser')

            # Get title
            title_tag = soup.find('title')
            title = title_tag.get_text().strip() if title_tag else path.stem

            # Get text
            text = soup.get_text(separator='\n\n')
            text = re.sub(r'\n{3,}', '\n\n', text).strip()

            # Split into pages
            page_size = 3000
            pages = []
            for i, j in enumerate(range(0, len(text), page_size)):
                chunk = text[j:j + page_size]
                pages.append(Page(number=i + 1, content=chunk))

            chapters = [Chapter(number=1, title="Full Text", pages=pages)]

            return Book(
                path=path,
                title=title,
                author=None,
                chapters=chapters,
                format="mobi"
            )

    def get_metadata(self, path: Path) -> dict:
        # MOBI metadata requires extraction, so just return basics
        return {
            "title": path.stem,
            "author": None,
            "format": "mobi",
        }


# =============================================================================
# TXT Extractor
# =============================================================================


class TXTExtractor:
    """Extract content from plain text files."""

    extensions = [".txt", ".text", ".md", ".markdown"]

    def can_handle(self, path: Path) -> bool:
        return path.suffix.lower() in self.extensions

    def extract(self, path: Path) -> Book:
        with open(path, 'r', encoding='utf-8', errors='ignore') as f:
            text = f.read()

        # Split into pages (~3000 chars each)
        page_size = 3000
        pages = []
        for i, j in enumerate(range(0, len(text), page_size)):
            chunk = text[j:j + page_size]
            pages.append(Page(number=i + 1, content=chunk))

        # Try to detect chapters by looking for patterns like "Chapter 1" or "CHAPTER ONE"
        chapters = self._detect_chapters(text, pages)

        return Book(
            path=path,
            title=path.stem,
            author=None,
            chapters=chapters,
            format="txt"
        )

    def _detect_chapters(self, text: str, pages: list[Page]) -> list[Chapter]:
        """Try to detect chapters from text patterns."""
        # Simple pattern matching for chapter headings
        chapter_pattern = re.compile(
            r'^(?:chapter|part)\s+(?:\d+|[ivxlc]+|one|two|three|four|five|six|seven|eight|nine|ten)',
            re.IGNORECASE | re.MULTILINE
        )

        matches = list(chapter_pattern.finditer(text))

        if not matches:
            return [Chapter(number=1, title="Full Text", pages=pages)]

        chapters = []
        for i, match in enumerate(matches):
            start_pos = match.start()
            end_pos = matches[i + 1].start() if i + 1 < len(matches) else len(text)

            # Find which pages fall in this range
            chapter_pages = []
            current_pos = 0
            for page in pages:
                page_start = current_pos
                page_end = current_pos + len(page.content)
                if page_start < end_pos and page_end > start_pos:
                    chapter_pages.append(page)
                current_pos = page_end

            chapters.append(Chapter(
                number=i + 1,
                title=match.group().strip(),
                pages=chapter_pages
            ))

        return chapters if chapters else [Chapter(number=1, title="Full Text", pages=pages)]

    def get_metadata(self, path: Path) -> dict:
        with open(path, 'r', encoding='utf-8', errors='ignore') as f:
            text = f.read()

        return {
            "title": path.stem,
            "author": None,
            "format": "txt",
            "char_count": len(text),
            "page_count": (len(text) // 3000) + 1,
        }


# =============================================================================
# Extractor Registry
# =============================================================================


EXTRACTORS: list[Extractor] = [
    PDFExtractor(),
    EPUBExtractor(),
    MOBIExtractor(),
    TXTExtractor(),
]


def get_extractor(path: Path) -> Extractor:
    """Get the appropriate extractor for a file."""
    for extractor in EXTRACTORS:
        if extractor.can_handle(path):
            return extractor
    raise ValueError(f"Unsupported file format: {path.suffix}")


# =============================================================================
# BM25 Search
# =============================================================================


class BookSearcher:
    """BM25-based search for book content."""

    def __init__(self, book: Book):
        from rank_bm25 import BM25Okapi

        self.book = book
        self.chunks: list[tuple[int, int, str]] = []  # (chapter, page, text)

        # Build chunks from book
        for chapter in book.chapters:
            for page in chapter.pages:
                # Split page into paragraphs
                paragraphs = [p.strip() for p in page.content.split('\n\n') if p.strip()]
                for para in paragraphs:
                    if len(para) > 50:  # Skip very short fragments
                        self.chunks.append((chapter.number, page.number, para))

        # Tokenize for BM25
        tokenized = [self._tokenize(chunk[2]) for chunk in self.chunks]
        self.bm25 = BM25Okapi(tokenized)

    def _tokenize(self, text: str) -> list[str]:
        """Simple tokenization."""
        # Lowercase and split on non-alphanumeric
        words = re.findall(r'\w+', text.lower())
        return words

    def search(self, query: str, top_k: int = 5) -> list[dict]:
        """Search for query and return top matches with context."""
        tokenized_query = self._tokenize(query)
        scores = self.bm25.get_scores(tokenized_query)

        # Get top-k indices
        top_indices = sorted(range(len(scores)), key=lambda i: scores[i], reverse=True)[:top_k]

        results = []
        for idx in top_indices:
            if scores[idx] > 0:
                chapter, page, text = self.chunks[idx]
                results.append({
                    "chapter": chapter,
                    "page": page,
                    "score": round(scores[idx], 3),
                    "text": text[:500] + "..." if len(text) > 500 else text,
                })

        return results


# =============================================================================
# Cache
# =============================================================================


CACHE_DIR = Path.home() / ".cache" / "book-reader"


def get_cache_key(path: Path) -> str:
    """Generate cache key from file path and mtime."""
    stat = path.stat()
    key_str = f"{path.absolute()}:{stat.st_mtime}:{stat.st_size}"
    return hashlib.md5(key_str.encode()).hexdigest()


def get_cached_book(path: Path) -> Book | None:
    """Load book from cache if available."""
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    cache_file = CACHE_DIR / f"{get_cache_key(path)}.json"

    if cache_file.exists():
        try:
            with open(cache_file, 'r') as f:
                data = json.load(f)

            chapters = []
            for ch in data['chapters']:
                pages = [Page(**p) for p in ch['pages']]
                chapters.append(Chapter(number=ch['number'], title=ch['title'], pages=pages))

            return Book(
                path=Path(data['path']),
                title=data['title'],
                author=data['author'],
                chapters=chapters,
                format=data['format']
            )
        except Exception:
            return None
    return None


def cache_book(book: Book) -> None:
    """Save book to cache."""
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    cache_file = CACHE_DIR / f"{get_cache_key(book.path)}.json"

    data = {
        'path': str(book.path),
        'title': book.title,
        'author': book.author,
        'format': book.format,
        'chapters': [
            {
                'number': ch.number,
                'title': ch.title,
                'pages': [{'number': p.number, 'content': p.content} for p in ch.pages]
            }
            for ch in book.chapters
        ]
    }

    with open(cache_file, 'w') as f:
        json.dump(data, f)


def load_book(path: Path) -> Book:
    """Load a book, using cache if available."""
    path = path.expanduser().resolve()

    if not path.exists():
        raise FileNotFoundError(f"File not found: {path}")

    # Try cache first
    book = get_cached_book(path)
    if book:
        return book

    # Extract and cache
    extractor = get_extractor(path)
    book = extractor.extract(path)
    cache_book(book)

    return book


# =============================================================================
# CLI
# =============================================================================


@click.group()
def cli():
    """Book Reader - Read and search digital books."""
    pass


@cli.command()
@click.argument('file', type=click.Path(exists=True))
def info(file: str):
    """Show book metadata and info."""
    path = Path(file).expanduser().resolve()
    extractor = get_extractor(path)
    meta = extractor.get_metadata(path)

    click.echo(f"File: {path.name}")
    click.echo(f"Format: {meta.get('format', 'unknown')}")
    click.echo(f"Title: {meta.get('title', 'Unknown')}")
    if meta.get('author'):
        click.echo(f"Author: {meta['author']}")
    if meta.get('page_count'):
        click.echo(f"Pages: {meta['page_count']}")
    if meta.get('chapter_count'):
        click.echo(f"Chapters: {meta['chapter_count']}")


@cli.command()
@click.argument('file', type=click.Path(exists=True))
def toc(file: str):
    """Show table of contents."""
    book = load_book(Path(file))

    click.echo(f"Table of Contents: {book.title}")
    click.echo("=" * 50)

    for ch in book.chapters:
        page_range = f"(pages {ch.pages[0].number}-{ch.pages[-1].number})" if ch.pages else ""
        click.echo(f"{ch.number}. {ch.title} {page_range}")


@cli.command()
@click.argument('file', type=click.Path(exists=True))
@click.option('--chapter', '-c', type=int, help='Read specific chapter')
@click.option('--page', '-p', type=int, help='Read specific page')
@click.option('--start', '-s', type=int, default=0, help='Start position (chars)')
@click.option('--length', '-l', type=int, default=5000, help='Length to read (chars)')
def read(file: str, chapter: int | None, page: int | None, start: int, length: int):
    """Read book content."""
    book = load_book(Path(file))

    if chapter is not None:
        ch = book.get_chapter(chapter)
        if not ch:
            click.echo(f"Chapter {chapter} not found. Available: 1-{len(book.chapters)}", err=True)
            return
        click.echo(f"=== Chapter {ch.number}: {ch.title} ===\n")
        click.echo(ch.content)
    elif page is not None:
        pg = book.get_page(page)
        if not pg:
            click.echo(f"Page {page} not found. Available: 1-{book.page_count}", err=True)
            return
        click.echo(f"=== Page {pg.number} ===\n")
        click.echo(pg.content)
    else:
        # Read from start position
        full_text = "\n\n".join(p.content for p in book.all_pages)
        excerpt = full_text[start:start + length]
        click.echo(excerpt)


@cli.command()
@click.argument('file', type=click.Path(exists=True))
@click.argument('query')
@click.option('--top', '-n', type=int, default=5, help='Number of results')
def search(file: str, query: str, top: int):
    """Search for text in the book."""
    book = load_book(Path(file))
    searcher = BookSearcher(book)
    results = searcher.search(query, top_k=top)

    if not results:
        click.echo("No results found.")
        return

    click.echo(f"Search results for '{query}' in {book.title}:")
    click.echo("=" * 60)

    for i, result in enumerate(results, 1):
        click.echo(f"\n[{i}] Chapter {result['chapter']}, Page {result['page']} (score: {result['score']})")
        click.echo("-" * 40)
        click.echo(result['text'])


@cli.command()
@click.argument('file', type=click.Path(exists=True))
def extract(file: str):
    """Extract full text from book."""
    book = load_book(Path(file))

    for page in book.all_pages:
        click.echo(page.content)
        click.echo("\n---\n")


if __name__ == '__main__':
    cli()
