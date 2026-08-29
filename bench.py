#!/usr/bin/env python3
"""A/B benchmark for llama.cpp: baseline vs MTP speculative decoding.

Starts llama-server, waits for health, runs fixed prompts, reports tok/s and
(when speculating) the draft acceptance rate. Refuses to run if free memory is
too low to hold the model, so it can't thrash the box.
"""
import json, os, signal, subprocess, sys, time, urllib.request

BIN   = os.path.expanduser("~/Projects/llama.cpp/build/bin/llama-server")
MODEL = os.path.expanduser("~/Models/Qwen3.8-27B-GGUF/Qwen3.8-27B-UD-IQ3_XXS.gguf")
MTP   = os.path.expanduser("~/Models/Qwen3.8-27B-GGUF/MTP/mtp-Qwen3.8-27B-Q4_0.gguf")
TMP   = "/Users/trevor/.claude/jobs/4c82aa1c/tmp"
PORT  = 18110
CTX   = int(os.environ.get("BENCH_CTX", "8192"))
NPRED = int(os.environ.get("BENCH_NPRED", "256"))

# code-gen is speculation-friendly (predictable tokens); prose is hostile.
# Bracketing both gives the real range rather than a best case.
PROMPTS = {
    "code": "Write a complete Python function that merges two sorted lists into "
            "one sorted list, with a docstring and type hints. Output only code.",
    "prose": "Explain, in flowing prose without lists, why unified memory changes "
             "the economics of running large language models on a laptop.",
}


def claimable_gb():
    out = subprocess.run(["vm_stat"], capture_output=True, text=True).stdout
    pg = {}
    for line in out.splitlines():
        if ":" in line:
            k, v = line.split(":", 1)
            try:
                pg[k.strip()] = int(v.strip().rstrip("."))
            except ValueError:
                pass
    # free + inactive + speculative is what a big allocation can realistically claim
    pages = (pg.get("Pages free", 0) + pg.get("Pages inactive", 0)
             + pg.get("Pages speculative", 0))
    return pages * 16384 / 1073741824


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


def run(label, extra_args):
    need = os.path.getsize(MODEL) / 1073741824
    if MTP in extra_args:
        need += os.path.getsize(MTP) / 1073741824
    have = claimable_gb()
    print(f"\n=== {label} ===")
    print(f"  needs ~{need:.1f} GB weights, claimable {have:.1f} GB")
    if have < need + 0.9:
        print(f"  SKIP: want >= {need + 0.9:.1f} GB claimable. Free memory first.")
        return None

    cmd = [BIN, "--model", MODEL, "--host", "127.0.0.1", "--port", str(PORT),
           "-ngl", "999", "--ctx-size", str(CTX),
           "--cache-type-k", "q8_0", "--cache-type-v", "q8_0", "--jinja"] + extra_args
    log = open(f"{TMP}/server-{label}.log", "w")
    proc = subprocess.Popen(cmd, stdout=log, stderr=subprocess.STDOUT,
                            preexec_fn=os.setsid)
    try:
        t0 = time.time()
        if not wait_health(proc):
            print(f"  FAILED to start -- see {TMP}/server-{label}.log")
            return None
        print(f"  loaded in {time.time() - t0:.0f}s")

        results = {}
        for name, prompt in PROMPTS.items():
            body = json.dumps({"prompt": prompt, "n_predict": NPRED,
                               "temperature": 0.7, "cache_prompt": False}).encode()
            req = urllib.request.Request(f"http://127.0.0.1:{PORT}/completion", body,
                                         {"Content-Type": "application/json"})
            with urllib.request.urlopen(req, timeout=3600) as r:
                d = json.loads(r.read())
            t = d.get("timings", {})
            tps = t.get("predicted_per_second", 0.0)
            line = f"  {name:6s} {tps:6.1f} tok/s ({t.get('predicted_n', 0)} tok)"
            dn, da = t.get("draft_n"), t.get("draft_n_accepted")
            if dn:
                line += f"  accept {da}/{dn} = {100.0 * da / dn:.0f}%"
            print(line)
            results[name] = tps
        return results
    finally:
        try:
            os.killpg(os.getpgid(proc.pid), signal.SIGTERM)
            proc.wait(timeout=30)
        except Exception:
            pass
        log.close()
        time.sleep(5)


if __name__ == "__main__":
    for p in (BIN, MODEL, MTP):
        if not os.path.exists(p):
            sys.exit(f"missing: {p}")
    base = run("baseline", [])
    spec = run("mtp", ["--spec-type", "draft-mtp", "-md", MTP])
    if base and spec:
        print("\n=== speedup ===")
        for k in base:
            if base[k]:
                print(f"  {k:6s} {spec[k] / base[k]:.2f}x  "
                      f"({base[k]:.1f} -> {spec[k]:.1f} tok/s)")
