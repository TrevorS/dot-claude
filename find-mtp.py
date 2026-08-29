#!/usr/bin/env python3
"""Hunt for an MTP / speculative sidecar for Qwen3.6-35B-A3B (the MoE)."""
import json, urllib.request, urllib.parse

UA = {"User-Agent": "curl/8"}


def get(url):
    req = urllib.request.Request(url, headers=UA)
    return json.load(urllib.request.urlopen(req, timeout=30))


def search(term, limit=15):
    u = "https://huggingface.co/api/models?" + urllib.parse.urlencode(
        {"search": term, "limit": limit, "sort": "downloads", "direction": -1})
    try:
        return get(u)
    except Exception as e:
        return [{"id": f"ERR {e}"}]


print("=== HF search ===")
for term in ["Qwen3.6-35B-A3B MTP", "Qwen3.6 MTP", "Qwen3.6-35B-A3B", "Qwen3.6-35B-A3B-GGUF"]:
    print(f"\n-- {term!r}")
    for m in search(term):
        print("   ", m.get("id"))

print("\n\n=== repo file listings: MTP sidecars? ===")
repos = [
    "Qwen/Qwen3.6-35B-A3B",
    "unsloth/Qwen3.6-35B-A3B-GGUF",
    "Qwen/Qwen3.8-27B",
    "unsloth/Qwen3.8-27B-GGUF",
]
for repo in repos:
    try:
        d = get(f"https://huggingface.co/api/models/{repo}")
        files = [s["rfilename"] for s in d.get("siblings", [])]
        mtp = [f for f in files
               if any(k in f.lower() for k in ("mtp", "draft", "eagle", "spec"))]
        print(f"\n-- {repo}  ({len(files)} files)")
        print("   MTP-ish:", mtp or "NONE")
    except Exception as e:
        print(f"\n-- {repo}: ERR {e}")

print("\n\n=== config.json: does the architecture declare MTP heads? ===")
for repo in ["Qwen/Qwen3.6-35B-A3B", "Qwen/Qwen3.8-27B"]:
    try:
        req = urllib.request.Request(
            f"https://huggingface.co/{repo}/raw/main/config.json", headers=UA)
        c = json.load(urllib.request.urlopen(req, timeout=30))
        hits = {k: v for k, v in c.items()
                if any(t in k.lower() for t in ("mtp", "nextn", "predict", "draft"))}
        print(f"\n-- {repo}")
        print("   arch:", c.get("architectures"))
        print("   MTP keys:", hits or "none")
    except Exception as e:
        print(f"\n-- {repo}: ERR {e}")
