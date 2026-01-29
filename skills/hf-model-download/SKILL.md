---
name: HuggingFace Model Download
description:
  When downloading models from HuggingFace, use this skill to get the correct
  command syntax. Triggers on "download model", "hf download", "huggingface
  download", "get model from huggingface", "pull model".
---

# HuggingFace Model Download

## Command Pattern

Always use `uv run` with the HuggingFace Hub package as an inline dependency:

```bash
uv run --with huggingface_hub hf download <repo> <file> --local-dir <path>
```

## Common Mistakes to Avoid

- **Wrong**: `pip install huggingface_hub && huggingface-cli download ...`
- **Wrong**: `uv run hf download ...` (missing `--with`)
- **Wrong**: `uv run --with "huggingface_hub[cli]" ...` (the `[cli]` extra doesn't exist, the CLI is included in the base package)

## Syntax Reference

### Download a specific file

```bash
uv run --with huggingface_hub hf download <org>/<repo> <filename> --local-dir <destination>
```

### Download multiple files

```bash
uv run --with huggingface_hub hf download <org>/<repo> <file1> <file2> --local-dir <destination>
```

### Download with glob pattern

```bash
uv run --with huggingface_hub hf download <org>/<repo> --include "*.gguf" --local-dir <destination>
```

### Download entire repo

```bash
uv run --with huggingface_hub hf download <org>/<repo> --local-dir <destination>
```

## Notes

- `HF_TOKEN` environment variable is used automatically for gated models
- `--local-dir` places files directly in the target directory (no nested `.cache` structure)
- Downloads are resumable — re-running the same command skips already-downloaded files
- For GGUF models, download only the quant you need rather than the whole repo
