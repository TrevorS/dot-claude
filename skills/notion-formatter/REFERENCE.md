# Notion Formatter Reference

## Table of Contents

1. [Detailed Syntax Guide](#detailed-syntax-guide)
2. [Feature Comparison Table](#feature-comparison-table)
3. [Notion-Specific Gotchas](#notion-specific-gotchas)
4. [Import Methods](#import-methods)
5. [Troubleshooting](#troubleshooting)
6. [Cheat Sheet](#cheat-sheet)

---

## Detailed Syntax Guide

### Text Formatting

| Feature       | Markdown     | Typing Works?   | Pasting Works?       | Result                      |
| ------------- | ------------ | --------------- | -------------------- | --------------------------- |
| Bold          | `**text**`   | ✅ Yes          | ✅ Yes               | **text**                    |
| Italic        | `*text*`     | ✅ Yes          | ✅ Yes               | _text_                      |
| Strikethrough | `~text~`     | ⚠️ Single tilde | ✅ Double `~~text~~` | ~~text~~                    |
| Inline code   | `` `code` `` | ✅ Yes          | ✅ Yes               | `code`                      |
| Underline     | `_text_`     | ❌ No           | ❌ No                | Use formatting menu instead |

**Best Practice:** Stick to bold, italic, and inline code. These work reliably everywhere.

---

### Headers

Notion supports 3 heading levels. Use standard markdown syntax:

```markdown
# Heading 1 (largest)

## Heading 2 (medium)

### Heading 3 (smallest)
```

**When Typing in Notion:**

- Type `#` + space to create H1
- Type `##` + space to create H2
- Type `###` + space to create H3

**When Pasting:**

- All three levels convert automatically

**Gotcha:** No H4, H5, H6 in Notion. Stop at H3 or convert extras to bold text.

---

### Lists

#### Bullet Lists

```markdown
- Item 1
- Item 2
  - Nested item 2a
  - Nested item 2b
- Item 3
```

Works with `*`, `-`, or `+`. Nesting uses indentation (2-4 spaces).

#### Numbered Lists

```markdown
1. First item
2. Second item
   a. Sub-item
   b. Sub-item 2
3. Third item
```

Use `1.`, `2.`, etc. Notion auto-increments. Nesting works with letters (a, b, c) or numbers.

#### Checkboxes

```markdown
[] Unchecked item
[x] Checked item (use lowercase x)
```

Create with `[]` at start of line. Toggle-friendly for to-do lists.

---

### Toggles vs. Blockquotes (Critical!)

**This is the #1 Notion gotcha.** The `>` character means different things:

#### Toggle Lists (Collapsible Sections)

```markdown
> Heading text
> This content is hidden until you click the toggle
> Can have multiple lines
> Can contain any block type (lists, code, etc.)
```

**When to Use:** Create collapsible sections, hide supplementary content, organize long documents.

**Features:**

- Keyboard shortcut: `Cmd/Ctrl + Option/Alt + T`
- Can nest multiple levels
- No way to set default open/closed state
- Users must click to expand

#### Blockquotes (Regular Quoted Text)

```markdown
" This is a blockquote
" Use the quote character, not greater-than
```

**When to Use:** Highlight quoted material, attribute sources, emphasis blocks.

**Key Difference:**

- `>` = toggle (collapsible)
- `"` = blockquote (always visible)

**Common Mistake:** Using `>` when you want a blockquote. Always use `"` instead.

---

### Code Blocks

Always specify the language for syntax highlighting:

```javascript
// JavaScript example
const greeting = "Hello, Notion!";
console.log(greeting);
```

```python
# Python example
def greet(name):
    return f"Hello, {name}!"
```

```sql
-- SQL example
SELECT * FROM users WHERE active = true;
```

#### Supported Languages (60+)

Common: JavaScript, Python, Java, C++, C#, Go, Rust, PHP, Ruby, TypeScript, HTML, CSS, SQL, Markdown, Bash, JSON, YAML, XML, and many more.

#### Syntax

````markdown
```language
code here
```
````

#### When Pasting Markdown with Code Blocks

- Notion auto-detects backtick fences
- **Important:** Must manually select language after paste
- Line numbers can be toggled in block menu
- Code wrapping can be enabled in `•••` menu

#### Inline Code

Use backticks for inline: ``[highlight `variable_name` here]``

---

### Tables

#### Standard Markdown Syntax

```markdown
| Header 1 | Header 2 | Header 3 |
| -------- | -------- | -------- |
| Cell 1   | Cell 2   | Cell 3   |
| Cell 4   | Cell 5   | Cell 6   |
```

#### How It Works

- **Typing in Notion:** Cannot use pipe syntax while typing
- **Copy/Paste:** Paste markdown table → converts automatically
- **Alternative:** Use `/table-inline` for simple table or `/table` for database

#### Complex Tables

- No nested tables
- Keep cells simple (text only, no markdown formatting inside cells)
- For complex data: consider creating manually in Notion using `/table`

#### Alignment

Notion doesn't support markdown alignment (`:---`, `:---:`, `---:`), but you can adjust in Notion after import.

---

### Images

#### Requirements

- **Must be hosted online** (full URLs)
- Local file paths don't work: ❌ `![alt](./local/image.png)`
- Public URLs work: ✅ `![alt](https://example.com/image.png)`

#### Syntax

```markdown
![Alt text describing the image](https://example.com/image.png)
```

#### When Pasting

- Links convert to clickable images
- Alt text is preserved as image caption
- Resizing: Can be done after import in Notion

#### If Images Don't Work

1. Verify URL is accessible (not behind auth)
2. Check file format (PNG, JPG, GIF, WebP supported)
3. Consider uploading images separately and adding them manually

---

### Links

#### Syntax

```markdown
[Link text](https://example.com)
[Internal link to another page](page-url)
```

#### When Typing vs. Pasting

- **While typing in Notion:** Markdown syntax doesn't work; use `/link` command
- **When pasting:** Standard markdown links convert automatically

#### Bare URLs

```markdown
https://example.com becomes a clickable link automatically
```

---

### Horizontal Rules

```markdown
---
```

Creates a visual divider. Use `---` on its own line.

---

## Feature Comparison Table

| Feature         | Works When Typing  | Works When Pasting | Notes                            |
| --------------- | ------------------ | ------------------ | -------------------------------- |
| Bold            | ✅                 | ✅                 | Always use `**`                  |
| Italic          | ✅                 | ✅                 | `*` or `_` both work             |
| Code (inline)   | ✅                 | ✅                 | Single backticks                 |
| Strikethrough   | ✅ Single `~`      | ✅ Double `~~`     | Different syntax                 |
| Headers (H1-H3) | ✅                 | ✅                 | `#`, `##`, `###`                 |
| Bullet list     | ✅                 | ✅                 | `-`, `*`, or `+`                 |
| Numbered list   | ✅                 | ✅                 | `1.`, `2.`, etc.                 |
| Checkbox        | ✅                 | ✅                 | `[]` or `[x]`                    |
| Toggle list     | ✅                 | ✅                 | `>` + space                      |
| Blockquote      | ✅                 | ✅                 | `"` + space (not `>`)            |
| Code block      | ✅                 | ✅                 | Language label recommended       |
| Horizontal rule | ✅                 | ✅                 | `---`                            |
| Links           | ❌ Use `/link`     | ✅                 | `[text](url)` works when pasting |
| Images          | ❌ Use `/image`    | ✅                 | `![alt](url)` works when pasting |
| Tables          | ❌ Use `/table`    | ✅                 | Pipe syntax works when pasting   |
| Equations       | ❌ Use `/equation` | ❌                 | LaTeX breaks on import           |
| Highlight       | ❌                 | ❌                 | `==text==` not supported         |
| Subscript       | ❌                 | ❌                 | `~text~` shows as strikethrough  |
| Superscript     | ❌                 | ❌                 | `^text^` not supported           |
| Footnotes       | ❌                 | ❌                 | `[^1]` not supported             |

---

## Notion-Specific Gotchas

### 1. Language Detection in Code Blocks

**Problem:** Paste a code block, language doesn't auto-select, no syntax highlighting.

**Solution:** Manually select language from dropdown in Notion (top-left of code block).

**Prevention:** Always include language label when formatting for paste: ` ```javascript `

### 2. Images Must Be Hosted Online

**Problem:** Local file paths don't work: `![](./image.png)`

**Solution:** Use full URLs: `![](https://example.com/image.png)`

**Alternative:** Paste markdown without images, then upload images manually in Notion using `/image` command.

### 3. Extra Line Breaks on Import

**Problem:** Notion adds extra blank lines around formatted elements.

**Solution:** Manually delete excess line breaks after pasting. This is normal and expected.

### 4. Tables Must Use Pipe Syntax

**Problem:** Cannot type table syntax in Notion while editing.

**Solution:** Either:

- Create table in external markdown editor, copy/paste into Notion
- Use `/table-inline` command for simple tables
- Use `/table` command for database-style tables

### 5. LaTeX/Math Equations Break

**Problem:** `$$equation$$` becomes garbled unicode characters.

**Solution:**

- Remove equations before pasting, OR
- Plan to recreate them manually in Notion using `/equation` block

**Note:** Notion has its own equation editor using LaTeX syntax, separate from markdown.

### 6. Large Documents May Fail to Paste

**Problem:** Pasting 10,000+ words may fail silently or partially import.

**Solution:** Break document into chunks (500-2000 words each), paste separately, reassemble in Notion.

### 7. No Nested Tables

**Problem:** Tables inside tables don't work.

**Solution:** Flatten structure or create manually in Notion using database relations.

---

## Import Methods

### Method 1: Direct Paste (Fastest)

1. Copy markdown text
2. Click in Notion and paste
3. Notion auto-converts formatting
4. Manually set code block languages, fix line breaks

**Best for:** Quick content, short responses, markdown already formatted

### Method 2: File Import

1. Sidebar → Import (three-dot menu)
2. Select Text & Markdown
3. Choose `.md` file
4. Notion converts file to page

**Best for:** Complete documents, structured files, preserving original organization

### Method 3: HTML Conversion (Advanced)

1. Convert markdown to HTML (pandoc, markdown-to-html tools)
2. Paste HTML into Notion
3. Notion renders HTML as blocks

**Best for:** Complex formatting, when markdown import has issues, preserving specific styles

---

## Troubleshooting

### Code Block Language Not Set

**Problem:** Pasted code block has no syntax highlighting.

**Solution:** Click language dropdown (top-left of block) → select language

**Prevention:** Always include language in markdown: ` ```python `

### Extra Blank Lines Everywhere

**Problem:** Notion added unnecessary line breaks.

**Solution:** Manually delete blank lines in Notion. This is normal when pasting.

**Prevention:** None—this is Notion behavior. Just clean up after paste.

### Links Not Clickable

**Problem:** Pasted links appear as plain text.

**Solution:**

- Click link text → type URL in the URL field that appears
- Or use `/link` command to create link manually

**Prevention:** Ensure links follow markdown syntax exactly: `[text](https://url)`

### Images Show as Broken Link

**Problem:** Image icon with 404 or broken appearance.

**Cause:** URL is not publicly accessible or file format not supported.

**Solution:**

- Verify URL works in browser
- Use common formats: PNG, JPG, GIF, WebP
- Upload to public hosting (imgur, GitHub, CDN)

### Table Paste Fails

**Problem:** Table markdown doesn't convert when pasted.

**Cause:** Table syntax error (misaligned pipes, missing separators)

**Solution:** Use `/table-inline` command instead, or verify markdown syntax is exact

### Equation Shows as Garbage

**Problem:** `$$math$$` becomes strange characters.

**Cause:** Notion doesn't support LaTeX in pasted markdown.

**Solution:** Recreate equation manually in Notion using `/equation` block

### Document Too Large to Paste

**Problem:** Large markdown file fails to import.

**Cause:** Notion has limits on paste size (typically 10,000+ words)

**Solution:** Break document into 500-2000 word chunks, paste separately, reassemble

### Strikethrough Looks Wrong

**Problem:** `~text~` shows strikethrough with single tilde, but pasted content needs `~~text~~`

**Solution:** Use double tilde `~~text~~` in markdown for pasting

---

## Cheat Sheet

### Quick Syntax Reference

**Text formatting:**

```markdown
**bold** _italic_ `code` ~strikethrough~
```

**Structure:**

```markdown
# H1

## H2

### H3

- bullet

1. numbered
   [] checkbox
   > toggle
   > " blockquote
   > --- divider
```

**Code blocks:**

```javascript
code;
```

**Tables and links:**

```markdown
| table | syntax |
| ----- | ------ |
| cell  | cell   |

[link](url)
![alt](url)
```

**Notion annotations:**

```markdown
[NOTION: Equations must be recreated manually]
[NOTION: Image URLs must be public/hosted online]
```

### Common Patterns

**Creating a section guide with toggles:**

```markdown
> Getting Started

1. First step
2. Second step

> Advanced Topics

- Topic A
- Topic B

> FAQ
> Q: How do I...?
> A: You can...
```

**Mixing code with explanation:**

Here's how to use the API:

```javascript
const api = require("example-api");
api.connect();
```

The `connect()` method initializes the connection. See below for options.

---

## Summary

**Key Takeaways:**

1. **Standard markdown mostly works** — use it freely for headers, lists, text formatting
2. **Toggles use `>`, blockquotes use `"`** — this is the most common mistake
3. **Paste works better than typing** — links, images, tables convert on paste
4. **Manual steps are normal** — callouts, equations, code language selection
5. **Break large documents** — don't try to paste 10,000 words at once
6. **Test and polish in Notion** — always review after paste and fix line breaks

**Golden Rule:** Keep markdown simple, annotate manual steps clearly, and always review in Notion before publishing.
