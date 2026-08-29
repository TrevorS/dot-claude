#!/usr/bin/env python3
"""Benchmark Qwen3.6-35B-A3B (MoE, 3B active) against the Qwen3.8-27B dense numbers.

Same prompts, context and KV quant as diag.py so the tok/s are directly
comparable. Also confirms the rebuilt llama.cpp loads this file at all -- the
old build (b873) died on a Metal residency assert.
"""
import json, os, signal, subprocess, time, urllib.request

BIN   = os.path.expanduser("~/Projects/llama.cpp/build/bin/llama-server")
MODEL = os.path.expanduser(
    "~/Models/Qwen3.6-35B-A3B-GGUF/Qwen3.6-35B-A3B-UD-IQ3_XXS.gguf")
TMP   = "/Users/trevor/.claude/jobs/4c82aa1c/tmp"
PORT  = 18112
NPRED = 256

PROMPTS = [
    ("prose", "Explain, in flowing prose without lists, why unified memory changes "
              "the economics of running large language models on a laptop."),
    ("code",  "Write a complete Python function that merges two sorted lists into "
              "one sorted list, with a docstring and type hints. Output only code."),
    ("prose2", "Describe, in flowing prose, how speculative decoding trades extra "
               "compute for reduced memory bandwidth per generated token."),
]

# A tool-calling probe: the whole point of this model is driving hermes, and
# tool-call reliability is what degrades first under aggressive quantization.
TOOLS = [{
    "type": "function",
    "function": {
        "name": "get_weather",
        "description": "Get the current weather for a city",
        "parameters": {
            "type": "object",
            "properties": {"city": {"type": "string", "description": "City name"}},
            "required": ["city"],
        },
    },
}]


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


def main():
    cmd = [BIN, "--model", MODEL, "--host", "127.0.0.1", "--port", str(PORT),
           "-ngl", "999", "--ctx-size", "8192",
           "--cache-type-k", "q8_0", "--cache-type-v", "q8_0", "--jinja"]
    log = open(f"{TMP}/moe.log", "w")
    proc = subprocess.Popen(cmd, stdout=log, stderr=subprocess.STDOUT, preexec_fn=os.setsid)
    print("=== Qwen3.6-35B-A3B UD-IQ3_XXS (MoE, 3B active) ===")
    t0 = time.time()
    try:
        if not wait_health(proc):
            print(f"  FAILED to load -- see {TMP}/moe.log")
            return
        print(f"  loaded in {time.time() - t0:.0f}s")

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
            print(f"  {name:7s} {t.get('predicted_per_second', 0):5.1f} tok/s"
                  f"  | free {f0:4.1f}->{f1:4.1f} GB  compressor {c0:4.1f}->{c1:4.1f} GB")

        # tool call probe
        print("\n  -- tool-calling probe --")
        body = json.dumps({
            "model": "local",
            "messages": [{"role": "user", "content": "What's the weather in Austin?"}],
            "tools": TOOLS, "tool_choice": "auto", "temperature": 0.3,
        }).encode()
        req = urllib.request.Request(f"http://127.0.0.1:{PORT}/v1/chat/completions",
                                     body, {"Content-Type": "application/json"})
        with urllib.request.urlopen(req, timeout=600) as r:
            d = json.loads(r.read())
        msg = d["choices"][0]["message"]
        tc = msg.get("tool_calls")
        if tc:
            fn = tc[0]["function"]
            print(f"     OK: {fn['name']}({fn['arguments']})")
        else:
            print(f"     NO TOOL CALL. content: {str(msg.get('content'))[:200]!r}")
    finally:
        try:
            os.killpg(os.getpgid(proc.pid), signal.SIGTERM)
            proc.wait(timeout=30)
        except Exception:
            pass
        log.close()


if __name__ == "__main__":
    main()
