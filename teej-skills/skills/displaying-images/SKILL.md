---
name: displaying-images
description: Display images in the terminal using the Kitty graphics protocol via kitty-img. Use when the user asks to show, display, view, preview, or render an image file (PNG, JPG, GIF, SVG, etc.) in the terminal, or when you want to visually present a generated image.
---

# Image Display Skill

Display images inline in the terminal using the Kitty graphics protocol. Works in Ghostty, Kitty, and WezTerm. In tmux, uses direct pty writes to bypass DCS passthrough entirely.

**Triggers:** show image, display image, view image, preview image, render image, kitty-img, kitty protocol

## Usage

**Always use `--popup`** when calling from Claude Code — it's the most reliable mode.

```bash
kitty-img --popup <image-file> [max-width-cols]
```

- `image-file` — path to any image (PNG, JPG, GIF, SVG, WebP, etc.). ImageMagick handles conversion.
- `max-width-cols` — display width in terminal columns (default: auto-fit to 80% of window)

Split pane mode (without `--popup`) also works but shows a title bar and dismiss prompt.

## How It Works

- **In tmux (both modes)**: Writes Kitty escape sequences directly to the client tty, bypassing tmux entirely. No `allow-passthrough` needed.
- **Outside tmux**: Renders the image inline at the cursor position via stdout.
- **Over SSH**: Works transparently — the local terminal (Ghostty) does the rendering regardless of where the tmux session originated.
- **Aspect ratio**: Only the column width is sent to the Kitty protocol (`c=N`). The terminal calculates the correct height from the image's native aspect ratio. Popup/pane sizing uses actual cell pixel dimensions from tmux.

## Examples

```bash
# Show a screenshot (popup, auto-sized)
kitty-img --popup /tmp/screenshot.png

# Preview at a specific width
kitty-img --popup diagram.svg 40

# Split pane mode (has title + dismiss prompt)
kitty-img /tmp/screenshot.png

# Quick test that the protocol works
kitty-img-test
```

## Requirements

- Terminal with Kitty graphics protocol support (Ghostty, Kitty, WezTerm)
- `magick` (ImageMagick) for format conversion and resizing
- `tmux` 3.3a+ for popup/split pane modes

## Limitations

- Claude Code's Bash tool captures stdout, so images cannot render inline in Claude Code output. The tmux popup/split is the workaround.
- Popup mode writes to the outer terminal pty — positioning is approximate.
