# Book Reader - Command Reference

## Installation

The script uses PEP 723 inline dependencies. No installation needed - just run with `uv`:

```bash
uv run ~/.claude/skills/book-reader/book.py <command> [options]
```

## Commands

### info

Show book metadata without full extraction.

```bash
uv run ~/.claude/skills/book-reader/book.py info <file>
```

**Output:**

- File name
- Format (pdf/epub/mobi/txt)
- Title (from metadata or filename)
- Author (if available)
- Page count
- Chapter count

**Example:**

```text
$ uv run ~/.claude/skills/book-reader/book.py info ~/Books/kant.pdf
File: kant.pdf
Format: pdf
Title: The Critique of Pure Reason
Author: Immanuel Kant
Pages: 357
Chapters: 3
```

---

### toc

Show table of contents with chapter titles and page ranges.

```bash
uv run ~/.claude/skills/book-reader/book.py toc <file>
```

**Example:**

```text
$ uv run ~/.claude/skills/book-reader/book.py toc ~/Books/alice.epub
Table of Contents: Alice's Adventures in Wonderland
==================================================
1. Down the Rabbit-Hole (pages 1-5)
2. The Pool of Tears (pages 5-8)
3. A Caucus-Race and a Long Tale (pages 8-12)
...
```

---

### read

Read book content by chapter, page, or character range.

```bash
uv run ~/.claude/skills/book-reader/book.py read <file> [options]
```

**Options:**

| Option            | Description                             |
| ----------------- | --------------------------------------- |
| `--chapter, -c N` | Read chapter N                          |
| `--page, -p N`    | Read page N                             |
| `--start, -s N`   | Start position in chars (default: 0)    |
| `--length, -l N`  | Length to read in chars (default: 5000) |

**Examples:**

```bash
# Read chapter 3
uv run ~/.claude/skills/book-reader/book.py read book.pdf --chapter 3

# Read page 42
uv run ~/.claude/skills/book-reader/book.py read book.epub --page 42

# Read first 2000 characters
uv run ~/.claude/skills/book-reader/book.py read book.txt --length 2000

# Read from position 10000, next 3000 chars
uv run ~/.claude/skills/book-reader/book.py read book.pdf --start 10000 --length 3000
```

---

### search

Search for text using BM25 ranking algorithm.

```bash
uv run ~/.claude/skills/book-reader/book.py search <file> <query> [options]
```

**Options:**

| Option        | Description                    |
| ------------- | ------------------------------ |
| `--top, -n N` | Number of results (default: 5) |

**Output includes:**

- Result rank
- Chapter and page location
- Relevance score
- Text excerpt (max 500 chars)

**Example:**

```text
$ uv run ~/.claude/skills/book-reader/book.py search kant.pdf "transcendental"
Search results for 'transcendental' in The Critique of Pure Reason:
============================================================

[1] Chapter 1, Page 175 (score: 2.405)
----------------------------------------
It may be said that the object of a merely transcendental idea is
something of which we have no conception...

[2] Chapter 1, Page 56 (score: 2.402)
----------------------------------------
Of Transcendental Logic. General logic, as we have seen, makes
abstraction of all content of cognition...
```

---

### extract

Extract full text from book (for piping to other tools).

```bash
uv run ~/.claude/skills/book-reader/book.py extract <file>
```

Pages are separated by `\n---\n`.

**Example:**

```bash
# Extract and count words
uv run ~/.claude/skills/book-reader/book.py extract book.pdf | wc -w

# Extract and search with grep
uv run ~/.claude/skills/book-reader/book.py extract book.epub | grep -i "philosophy"
```

---

## Caching

Extracted books are cached in `~/.cache/book-reader/` for faster subsequent access.

- Cache key: hash of file path + modification time + file size
- Automatic invalidation when source file changes
- JSON format for portability

To clear the cache:

```bash
rm -rf ~/.cache/book-reader/
```

---

## Supported Formats

### PDF (.pdf)

- Uses PyMuPDF (fitz) for extraction
- Preserves page numbers
- Extracts TOC when available
- Reads metadata (title, author)

### EPUB (.epub)

- Uses ebooklib for parsing
- Chapters extracted from spine
- Full Dublin Core metadata support
- HTML content converted to plain text

### MOBI (.mobi, .azw, .azw3)

- Uses mobi package (KindleUnpack fork)
- Extracts to temp directory, parses HTML
- Basic metadata only

### Text (.txt, .text, .md, .markdown)

- Direct file reading
- Attempts chapter detection via patterns (e.g., "Chapter 1", "CHAPTER I")
- Chunks into ~3000 char "pages"

---

## Notes

- All file paths can use `~` for home directory
- Large books may take a few seconds on first access (cached afterward)
- BM25 search works best with multi-word queries
- Chapter detection varies by format and book structure
