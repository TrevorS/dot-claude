#!/usr/bin/env python3
"""Is the MTP slowdown memory pressure or genuine speculation overhead?

Baseline was flat (7.1/7.1) but MTP degraded across the run (6.2 -> 4.1). That
could be (a) prose simply speculating worse than code, or (b) the box running
out of memory as the run proceeds. Reversing the prompt order separates them:
  - prose fast first, code slow second  -> memory pressure (order-dependent)
  - prose slow either way               -> genuine acceptance effect
Samples free memory around every request so the pressure is visible either way.
"""
import json, os, signal, subprocess, time, urllib.request

BIN   = os.path.expanduser("~/Projects/llama.cpp/build/bin/llama-server")
MODEL = os.path.expanduser("~/Models/Qwen3.8-27B-GGUF/Qwen3.8-27B-UD-IQ3_XXS.gguf")
MTP   = os.path.expanduser("~/Models/Qwen3.8-27B-GGUF/MTP/mtp-Qwen3.8-27B-Q4_0.gguf")
TMP   = "/Users/trevor/.claude/jobs/4c82aa1c/tmp"
PORT  = 18111
NPRED = 256

PROMPTS = [
    ("prose", "Explain, in flowing prose without lists, why unified memory changes "
              "the economics of running large language models on a laptop."),
    ("code",  "Write a complete Python function that merges two sorted lists into "
              "one sorted list, with a docstring and type hints. Output only code."),
    ("prose2", "Describe, in flowing prose, how speculative decoding trades extra "
               "compute for reduced memory bandwidth per generated token."),
]


def mem():
    out = subprocess.run(["vm_stat"], capture_output=True, text=True).stdout
    pg = {}
    for line in out.splitlines():
        if ":" in line:
            k, v = line.split(":", 1)
            try:
                pg[k.strip()] = int(v.strip().rstrip("."))
            except ValueError:
                pass
    free = (pg.get("Pages free", 0) + pg.get("Pages speculative", 0)) * 16384 / 2**30
    comp = pg.get("Pages occupied by compressor", 0) * 16384 / 2**30
    return free, comp


def wait_health(proc, timeout=900):
    t0 = time.time()
    while time.time() - t0 < timeout:
        if proc.poll() is not None:
            return False
        try:
            with urllib.request.urlopen(f"http://127.0.0.1:{PORT}/health", timeout=3) as r:
                if r.status == 200:
                    return True
        except Exception:
            time.sleep(2)
    return False


def run(label, extra):
    cmd = [BIN, "--model", MODEL, "--host", "127.0.0.1", "--port", str(PORT),
           "-ngl", "999", "--ctx-size", "8192",
           "--cache-type-k", "q8_0", "--cache-type-v", "q8_0", "--jinja"] + extra
    log = open(f"{TMP}/diag-{label}.log", "w")
    proc = subprocess.Popen(cmd, stdout=log, stderr=subprocess.STDOUT, preexec_fn=os.setsid)
    print(f"\n=== {label} ===")
    try:
        if not wait_health(proc):
            print(f"  FAILED -- see {TMP}/diag-{label}.log")
            return
        for name, prompt in PROMPTS:
            f0, c0 = mem()
            body = json.dumps({"prompt": prompt, "n_predict": NPRED,
                               "temperature": 0.7, "cache_prompt": False}).encode()
            req = urllib.request.Request(f"http://127.0.0.1:{PORT}/completion", body,
                                         {"Content-Type": "application/json"})
            with urllib.request.urlopen(req, timeout=3600) as r:
                d = json.loads(r.read())
            t = d.get("timings", {})
            f1, c1 = mem()
            line = (f"  {name:7s} {t.get('predicted_per_second', 0):5.1f} tok/s"
                    f"  | free {f0:4.1f}->{f1:4.1f} GB  compressor {c0:4.1f}->{c1:4.1f} GB")
            dn, da = t.get("draft_n"), t.get("draft_n_accepted")
            if dn:
                line += f"  accept {100.0 * da / dn:.0f}%"
            print(line)
    finally:
        try:
            os.killpg(os.getpgid(proc.pid), signal.SIGTERM)
            proc.wait(timeout=30)
        except Exception:
            pass
        log.close()
        time.sleep(5)


if __name__ == "__main__":
    print("free/compressor sampled around each request; prompt order reversed vs bench.py")
    run("mtp-ngld", ["--spec-type", "draft-mtp", "-md", MTP, "-ngld", "999"])
    run("baseline", [])
