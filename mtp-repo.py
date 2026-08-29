#!/usr/bin/env python3
"""List quant + sidecar files for the Qwen3.6 MTP repos and the DFlash one."""
import json, urllib.request

UA = {"User-Agent": "curl/8"}
REPOS = [
    "unsloth/Qwen3.6-35B-A3B-MTP-GGUF",
    "unsloth/Qwen3.6-27B-MTP-GGUF",
    "Alittlehammmer/Qwen3.6-35B-A3B-DFlash-GGUF-llama.cpp",
]

for repo in REPOS:
    print(f"\n=== {repo} ===")
    try:
        req = urllib.request.Request(
            f"https://huggingface.co/api/models/{repo}?blobs=true", headers=UA)
        d = json.load(urllib.request.urlopen(req, timeout=30))
        print("  lastModified:", d.get("lastModified"))
        sib = [(s.get("size") or 0, s["rfilename"]) for s in d.get("siblings", [])
               if s["rfilename"].endswith(".gguf")]
        side = [x for x in sib if any(k in x[1].lower()
                                      for k in ("mtp", "draft", "dflash", "eagle"))]
        main = [x for x in sib if x not in side]
        print("  -- sidecars --")
        for s, n in sorted(side):
            print(f"     {s / 1073741824:6.2f} GB  {n}")
        print("  -- main quants (8-16 GB band) --")
        for s, n in sorted(main):
            if 7e9 < s < 1.7e10:
                print(f"     {s / 1073741824:6.2f} GB  {n}")
    except Exception as e:
        print("  ERR", e)
