# gifsicle — GIF optimization

Optimize GIF files using gifsicle. Use when compressing, resizing, or inspecting animated GIFs.

## Install

```bash
brew install gifsicle
```

Always check `which gifsicle` first. If missing, install via brew before proceeding.

## Quick Reference

```bash
# Inspect a gif (frames, dimensions, colors, delays)
gifsicle -I input.gif

# Recommended optimization (good balance of size vs quality)
gifsicle -O3 --lossy=80 --colors=128 --resize-width WIDTH input.gif -o output.gif

# Aggressive optimization (smaller, slight quality loss)
gifsicle -O3 --lossy=100 --colors=64 --resize-width WIDTH input.gif -o output.gif

# Light optimization (preserve quality)
gifsicle -O3 --lossy=30 input.gif -o output.gif

# Drop every other frame (halve frame count, double delay to keep speed)
gifsicle input.gif $(seq -f '#%g' 0 2 $(gifsicle -I input.gif 2>&1 | head -1 | grep -o '[0-9]* images' | cut -d' ' -f1)) -d8 -o output.gif
```

## Key Flags

| Flag                | What it does                                          |
| ------------------- | ----------------------------------------------------- |
| `-O3`               | Maximum lossless compression                          |
| `--lossy=N`         | Lossy compression (30=light, 80=good, 100=aggressive) |
| `--colors=N`        | Max colors per frame (256 default, try 128 or 64)     |
| `--resize-width W`  | Scale to width, keep aspect ratio                     |
| `--resize-height H` | Scale to height, keep aspect ratio                    |
| `-I`                | Print info (frames, dimensions, color tables)         |
| `--delete '#N'`     | Delete frame N                                        |
| `-d N`              | Set delay to N centiseconds between frames            |

## Workflow

1. Run `which gifsicle || brew install gifsicle`
2. Run `gifsicle -I` first to understand the gif
3. Check current file size with `ls -lh`
4. Try recommended settings, compare sizes
5. Visually verify the output (use Read tool to preview)
6. Adjust `--lossy`, `--colors`, or `--resize-width` as needed
