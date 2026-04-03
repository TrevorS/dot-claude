---
name: displaying-images
description: Display images in the terminal using the Kitty graphics protocol via kitty-img. Use when the user asks to show, display, view, preview, or render an image file (PNG, JPG, GIF, SVG, etc.) in the terminal, or when you want to visually present a generated image.
---

# Image Display Skill

Display images inline in the terminal using the Kitty graphics protocol. Works in Ghostty, Kitty, and WezTerm. In tmux, opens a popup overlay with automatic cleanup.

**Triggers:** show image, display image, view image, preview image, render image, kitty-img, kitty protocol

## Usage

Run `kitty-img` via Bash to display any image file:

```bash
kitty-img [--popup] <image-file> [max-width-cols]
```

- `--popup` — use a tmux popup overlay instead of a split pane (popup uses direct pty writes)
- `image-file` — path to any image (PNG, JPG, GIF, SVG, WebP, etc.). ImageMagick handles conversion.
- `max-width-cols` — display width in terminal columns (default: auto-fit)

## How It Works

- **Split pane (default)**: Opens an auto-sized tmux split pane at the bottom. Uses DCS passthrough — tmux manages the image lifecycle. Title shown above image. Press any key to dismiss.
- **Popup (`--popup`)**: Opens an auto-sized tmux popup overlay. Uses direct pty write to the outer terminal. Cleans up image on dismiss.
- **Outside tmux**: Renders the image inline at the cursor position.
- **Over SSH**: Works transparently — the local terminal (Ghostty) does the rendering regardless of where the tmux session originated.

## Examples

```bash
# Show a screenshot
kitty-img /tmp/screenshot.png

# Preview a generated diagram at 40 columns wide
kitty-img diagram.svg 40

# Quick test that the protocol works
kitty-img-test
```

## Requirements

- Terminal with Kitty graphics protocol support (Ghostty, Kitty, WezTerm)
- `magick` (ImageMagick) for format conversion and resizing
- `tmux` 3.3a+ with `allow-passthrough on` for popup mode

## Limitations

- Claude Code's Bash tool captures stdout, so images cannot render inline in Claude Code output. The tmux popup is the workaround.
- Popup mode writes to the outer terminal pty at calculated coordinates — positioning is approximate.
- tmux `display-popup` does not support DCS passthrough, so the popup uses direct pty writes instead.
