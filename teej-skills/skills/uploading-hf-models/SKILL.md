---
name: uploading-hf-models
description: Upload model weights to HuggingFace at high speed using best practices. Use when pushing models, uploading safetensors, uploading GGUFs, or creating model repos on HuggingFace.
---

# Uploading Models to HuggingFace

## Prerequisites

```bash
# Install fast transfer backends
uv pip install hf_transfer hf_xet

# Must be logged in
huggingface-cli login
# or set HF_TOKEN env var
```

## Best Practices

### 1. Enable fast transfer

```bash
export HF_HUB_ENABLE_HF_TRANSFER=1  # Rust multi-connection uploads
export HF_HUB_DISABLE_XET=1         # Disable xet backend (has stalling bug as of April 2026)
```

Without `hf_transfer`, uploads use a single-threaded Python path at ~3 MB/s.
With it: limited by your upstream bandwidth.

**Note (April 2026):** The `hf_xet` backend has a known bug causing uploads >2GB to stall progressively. Disable it with `HF_HUB_DISABLE_XET=1` until fixed. See [HF forum thread](https://discuss.huggingface.co/t/upload-speeds-extremely-slow-stalling-since-april-1st/174910).

### 2. Upload individual files, not folders

For large models (>10GB), `upload_file` per-shard is more reliable than `upload_folder` or `upload_large_folder`. Each file gets its own commit — if the upload dies you don't lose progress.

No single LFS file can exceed 50GB. Split safetensors shards to stay under this limit.

### 3. Create repos as private first

Push private, verify, then flip to public. Avoids shipping broken weights.

### 4. Model card metadata

Every repo needs proper YAML frontmatter for discoverability:

```yaml
---
base_model: google/original-model-id
pipeline_tag: text-generation
library_name: transformers
language:
- en
license: apache-2.0
tags:
- your-tags
---
```

For GGUF quantization repos, add:

```yaml
base_model: your-username/your-bf16-repo
base_model_relation: quantized
```

### 5. Use collections

Group related models (bf16 + GGUF + variants) into a HF Collection for visibility.

### 6. Skip dotfiles and cache dirs

Transformers `save_pretrained()` creates `.cache/` dirs — filter these out before uploading.

### 7. Clean tensor names before saving

If using LoRA/PEFT, call `model.merge_and_unload()` before `save_pretrained()`. Otherwise tensor names contain `base_layer.weight` and `lora_` prefixes that break GGUF conversion.

### 8. Use safetensors, not pickle

Always save as `.safetensors`, never `.bin` or `.pth`. Safer and faster.

## CLI Tool

A standalone upload script is at `~/.local/bin/hf-upload`:

```bash
hf-upload models/my-model username/repo-name          # private by default
hf-upload models/my-model username/repo-name --public  # public
hf-upload models/my-model username/repo-name --dry-run # list files only
```

## Running via nohup (for large uploads)

```bash
HF_HUB_ENABLE_HF_TRANSFER=1 nohup hf-upload models/my-model user/repo > upload.log 2>&1 &
echo "PID: $! — tail -f upload.log"
```

## Common Issues

- **Upload stalls at ~50%**: Missing `HF_HUB_ENABLE_HF_TRANSFER=1`. The Python path uses a single HTTP connection that times out on large files.
- **`ValueError: cannot update files under .cache/`**: Filter out `.cache/` dirs created by transformers.
- **`base_layer.weight` tensor names**: Call `model.merge_and_unload()` before saving if using LoRA/PEFT.
- **Process dies, upload lost**: Use per-file uploads instead of `upload_folder`. Each file commits independently.
- **File >50GB**: HF has a 50GB hard limit per LFS file. Use `max_shard_size="20GB"` in `save_pretrained()` to split.
