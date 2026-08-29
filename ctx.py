#!/usr/bin/env python3
"""How much context can the MoE actually afford on this 24GB box?

The earlier benchmark ran with llama-server's default n_slots=4, which sizes the
KV pool for four concurrent requests. hermes is a single agent, so -np 1 should
buy back most of that. Walks ctx sizes upward at -np 1, measuring the real
memory cost of each and confirming the model still generates, and stops at the
first size that won't fit or that pushes the box into compression.
"""
import json, os, signal, subprocess, time, urllib.request

BIN   = os.path.expanduser("~/Projects/llama.cpp/build/bin/llama-server")
MODEL = os.path.expanduser(
    "~/Models/Qwen3.6-35B-A3B-GGUF/Qwen3.6-35B-A3B-UD-IQ3_XXS.gguf")
TMP   = "/Users/trevor/.claude/jobs/4c82aa1c/tmp"
PORT  = 18113
SIZES = [16384, 32768, 65536, 131072, 262144]


def stats():
    out = subprocess.run(["vm_stat"], capture_output=True, text=True).stdout
    pg = {}
    for line in out.splitlines():
        if ":" in line:
            k, v = line.split(":", 1)
            try:
                pg[k.strip()] = int(v.strip().rstrip("."))
            except ValueError:
                pass
    g = lambda k: pg.get(k, 0) * 16384 / 2**30
    # "total = 3072.00M  used = 2015.00M  free = 1057.00M  (encrypted)"
    sw = subprocess.run(["sysctl", "-n", "vm.swapusage"],
                        capture_output=True, text=True).stdout.split()
    used = 0.0
    if "used" in sw:
        try:
            used = float(sw[sw.index("used") + 2].rstrip("M")) / 1024
        except (ValueError, IndexError):
            pass
    return {"free": g("Pages free") + g("Pages speculative"),
            "wired": g("Pages wired down"),
            "comp": g("Pages occupied by compressor"),
            "swap": used}


def wait_health(proc, timeout=600):
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


def try_ctx(ctx):
    before = stats()
    cmd = [BIN, "--model", MODEL, "--host", "127.0.0.1", "--port", str(PORT),
           "-ngl", "999", "--ctx-size", str(ctx), "--parallel", "1",
           "--cache-type-k", "q8_0", "--cache-type-v", "q8_0", "--jinja"]
    log = open(f"{TMP}/ctx-{ctx}.log", "w")
    proc = subprocess.Popen(cmd, stdout=log, stderr=subprocess.STDOUT, preexec_fn=os.setsid)
    try:
        if not wait_health(proc):
            print(f"  {ctx:>7,}  FAILED to load  (see {TMP}/ctx-{ctx}.log)")
            return False
        loaded = stats()
        body = json.dumps({"prompt": "Write one sentence about memory bandwidth.",
                           "n_predict": 48, "temperature": 0.7}).encode()
        req = urllib.request.Request(f"http://127.0.0.1:{PORT}/completion", body,
                                     {"Content-Type": "application/json"})
        with urllib.request.urlopen(req, timeout=900) as r:
            d = json.loads(r.read())
        tps = d.get("timings", {}).get("predicted_per_second", 0)
        after = stats()
        wired_cost = loaded["wired"] - before["wired"]
        comp_growth = after["comp"] - before["comp"]
        swap_growth = after["swap"] - before["swap"]
        print(f"  {ctx:>7,}  wired +{wired_cost:5.2f} GB  "
              f"compressor {comp_growth:+5.2f} GB  swap {swap_growth:+5.2f} GB  "
              f"{tps:5.1f} tok/s")
        # Free memory sits near zero on macOS by design, so it says nothing.
        # Paying for context in compression or swap is the real failure, and so
        # is throughput collapsing because weights are being paged.
        return comp_growth < 1.0 and swap_growth < 0.5 and tps > 15.0
    finally:
        try:
            os.killpg(os.getpgid(proc.pid), signal.SIGTERM)
            proc.wait(timeout=30)
        except Exception:
            pass
        log.close()
        time.sleep(6)


if __name__ == "__main__":
    print("Qwen3.6-35B-A3B UD-IQ3_XXS (12.30 GB) at --parallel 1, q8_0 KV\n")
    print(f"  {'ctx':>7}  cost / headroom / throughput")
    for ctx in SIZES:
        if not try_ctx(ctx):
            print(f"\n  -> {ctx:,} is the first size that does not fit comfortably.")
            break
    else:
        print("\n  -> all tested sizes fit.")
