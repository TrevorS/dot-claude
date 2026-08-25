#!/usr/bin/env python3
"""Bidirectional schema-completeness audit for silently-validating config surfaces.

Some Claude Code config surfaces validate LOUDLY (settings.json -> zod, which raises
`unrecognized_keys`), and some validate SILENTLY. The theme loader is the canonical
silent one:

    if (Object.hasOwn(basePalette, key) && isValidColor(value)) merged[key] = value

A key that is not in the base palette is dropped with no warning, no error, and no
debug line. A key that is simply absent falls back to the built-in base value. Both
failure modes are invisible, so they rot indefinitely: release notes never mention
them, and the config keeps "working".

This script diffs each such surface against the schema in the INSTALLED BINARY --
the only source that decides what actually runs -- in both directions:

    missing  -> key exists in the schema, absent from your file (silent fallback)
    unknown  -> key in your file, absent from the schema  (silently dropped)
    invalid  -> value the surface's validator rejects      (silently dropped)
    suspect  -> value present and valid but semantically off (see below)

Usage:
    python3 schema-completeness.py                  # audit every surface
    python3 schema-completeness.py --surface themes
    python3 schema-completeness.py --strings CACHE  # reuse an extracted strings dump

Exit code 1 if any finding, 0 if clean -- so it can gate `make validate`.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

HOME = Path.home()
CLAUDE_DIR = HOME / ".claude"


# ---------------------------------------------------------------- binary access


def find_binary() -> Path:
    exe = shutil.which("claude")
    if not exe:
        sys.exit("claude not found on PATH")
    return Path(os.path.realpath(exe))


def binary_strings(cache: Path | None) -> str:
    """Extract (or reuse) the printable strings of the installed binary."""
    if cache and cache.exists():
        return cache.read_text(encoding="utf-8", errors="replace")
    out = subprocess.run(
        ["strings", str(find_binary())], capture_output=True, text=True, errors="replace"
    ).stdout
    if cache:
        cache.write_text(out, encoding="utf-8")
    return out


# ---------------------------------------------------------------- color helpers

# Mirrors the binary's theme color validator:
#   rgb(r,g,b) | #rrggbb | #rgb | ansi256(n) | ansi:<name>
# Note 8-digit hex (alpha) is NOT accepted.
_RGB = re.compile(r"rgb\(\s?\d{1,3},\s?\d{1,3},\s?\d{1,3}\s?\)")
_HEX6 = re.compile(r"#[0-9a-fA-F]{6}")
_HEX3 = re.compile(r"#[0-9a-fA-F]{3}")
_ANSI256 = re.compile(r"ansi256\(\d{1,3}\)")


def valid_color(v) -> bool:
    if not isinstance(v, str):
        return False
    return bool(
        _RGB.fullmatch(v)
        or _HEX6.fullmatch(v)
        or _HEX3.fullmatch(v)
        or _ANSI256.fullmatch(v)
        or v.startswith("ansi:")
    )


def to_rgb(v: str | None):
    if not v:
        return None
    m = _RGB.fullmatch(v)
    if m:
        return tuple(int(x) for x in re.findall(r"\d{1,3}", v))
    m = _HEX6.fullmatch(v)
    if m:
        h = v[1:]
        return tuple(int(h[i : i + 2], 16) for i in (0, 2, 4))
    m = _HEX3.fullmatch(v)
    if m:
        return tuple(int(c * 2, 16) for c in v[1:])
    return None  # ansi:* / ansi256() are terminal-defined; not comparable


def luminance(c) -> float:
    def f(x):
        x /= 255
        return x / 12.92 if x <= 0.03928 else ((x + 0.055) / 1.055) ** 2.4

    r, g, b = c
    return 0.2126 * f(r) + 0.7152 * f(g) + 0.0722 * f(b)


def contrast(a, b) -> float:
    la, lb = luminance(a), luminance(b)
    hi, lo = max(la, lb), min(la, lb)
    return (hi + 0.05) / (lo + 0.05)


# ---------------------------------------------------------------- themes surface

# Every built-in palette literal starts at `{autoAccept:` and ends at the last
# rainbow key. All built-ins carry an identical key set, which IS the set of keys
# a custom theme may override.
_PALETTE_END = re.compile(r'rainbow_violet_shimmer:"[^"]*"')
_PALETTE_START = "{autoAccept:"
_KV = re.compile(r'([A-Za-z_][A-Za-z0-9_]*):"([^"]*)"')


def builtin_palettes(strings: str) -> list[dict]:
    out = []
    for m in _PALETTE_END.finditer(strings):
        end = m.end()
        start = strings.rfind(_PALETTE_START, max(0, end - 9000), end)
        if start != -1:
            out.append(dict(_KV.findall(strings[start:end])))
    return out


def audit_themes(strings: str) -> list[str]:
    findings: list[str] = []
    theme_dir = CLAUDE_DIR / "themes"
    files = sorted(theme_dir.glob("*.json")) if theme_dir.is_dir() else []
    if not files:
        print("themes: no custom themes  ~")
        return findings

    palettes = builtin_palettes(strings)
    if not palettes:
        findings.append("themes: could not locate built-in palettes in the binary")
        return findings

    canon = max((list(p) for p in palettes), key=len)
    # Light/dark reference palettes let us tell an accent from a surface: surfaces
    # invert between the two themes, accents keep their hue and brighten in dark.
    hexy = [p for p in palettes if "ansi" not in str(p.get("text"))]
    light = next((p for p in hexy if p.get("text") == "rgb(0,0,0)"), None)
    dark = next((p for p in hexy if p.get("text") == "rgb(255,255,255)"), None)

    valid_bases = {
        "light",
        "dark",
        "light-ansi",
        "dark-ansi",
        "light-daltonized",
        "dark-daltonized",
    }

    for path in files:
        label = f"themes/{path.name}"
        try:
            doc = json.loads(path.read_text())
        except json.JSONDecodeError as e:
            findings.append(f"{label}: invalid JSON ({e}) -- loader skips the file entirely")
            continue

        base = doc.get("base", "dark")
        if base not in valid_bases:
            findings.append(f"{label}: base {base!r} is not a built-in; loader silently uses 'dark'")

        overrides = doc.get("overrides") or {}
        missing = [k for k in canon if k not in overrides]
        unknown = [k for k in overrides if k not in canon]
        invalid = [k for k, v in overrides.items() if not valid_color(v)]

        for k in missing:
            findings.append(f"{label}: missing {k!r} -- falls back to base {base!r}")
        for k in unknown:
            findings.append(f"{label}: unknown {k!r} -- silently dropped by the loader")
        for k in invalid:
            findings.append(f"{label}: invalid color {k!r}={overrides[k]!r} -- silently dropped")

        # Semantic check: an accent slot filled with a surface-dark color renders as
        # near-invisible text. Compare against the built-in for the same key rather
        # than a guessed terminal background, so the check needs no assumptions.
        if light and dark:
            for k, v in overrides.items():
                cl, cd, cm = to_rgb(light.get(k)), to_rgb(dark.get(k)), to_rgb(v)
                if not (cl and cd and cm):
                    continue
                ll, ld = luminance(cl), luminance(cd)
                is_surface = (ll > 0.5 and ld < 0.2) or (ll < 0.2 and ld > 0.5)
                if is_surface:
                    continue
                drift = contrast(cm, cd)
                if drift > 3.0:
                    findings.append(
                        f"{label}: suspect {k!r}={v} -- accent slot, but {drift:.1f}:1 away from "
                        f"the built-in {base} value {dark.get(k)}; likely mistaken for a surface fill"
                    )

        ok = len(canon) - len(missing)
        print(f"{label}: {ok}/{len(canon)} keys, base={base}")

    return findings


# -------------------------------------------------------------- settings surface


def audit_settings(strings: str) -> list[str]:
    """settings.json validates loudly (zod `unrecognized_keys`), so unknown keys
    cannot survive. The residual risk is the reverse: a key the product dropped
    that zod still tolerates. Confirm doc-absent keys against the binary --
    undocumented != stale (`@internal` keys are live but deliberately undocumented).
    """
    findings: list[str] = []
    path = CLAUDE_DIR / "settings.json"
    if not path.exists():
        return findings
    cfg = json.loads(path.read_text())

    def in_schema(leaf: str) -> bool:
        # A live key always appears in the binary as a zod shape entry `leaf:`.
        return f"{leaf}:" in strings

    def is_freeform(d: dict) -> bool:
        """Distinguish a schema object (sandbox, permissions) from a free-form map
        whose KEYS are user data (env, hooks, enabledPlugins, skillOverrides,
        extraKnownMarketplaces). Detected rather than blacklisted, so new maps in
        future versions don't produce a wall of false positives."""
        kids = list(d)
        if not kids:
            return False
        return sum(in_schema(k) for k in kids) / len(kids) < 0.5

    def walk(o, prefix=""):
        if isinstance(o, dict):
            for k, v in o.items():
                if k.startswith("$"):
                    continue
                name = f"{prefix}.{k}" if prefix else k
                yield name, v
                # `env` holds arbitrary pass-through variables, not schema keys --
                # audited separately below against the Claude-owned prefixes only.
                if isinstance(v, dict) and name != "env" and not is_freeform(v):
                    yield from walk(v, name)

    absent = [n for n, _ in walk(cfg) if not in_schema(n.rsplit(".", 1)[-1])]

    # An env var Claude Code doesn't read is usually the user's own (JJ_EDITOR,
    # PATH tweaks) -- harmless. But one carrying a Claude-owned prefix that the
    # binary has never heard of is a typo or a flag the product removed, and it
    # fails silently either way.
    owned = re.compile(r"^(CLAUDE_CODE_|CLAUDE_|ANTHROPIC_|OTEL_|MCP_|DISABLE_)")
    for name in cfg.get("env", {}):
        if owned.match(name) and name not in strings:
            findings.append(
                f"settings.json: env.{name} carries a Claude-owned prefix but does not "
                f"appear in the binary -- typo, or a flag the product dropped"
            )

    for name in absent:
        findings.append(f"settings.json: {name!r} has no zod shape entry in the binary -- verify before removing")

    print(f"settings.json: {sum(1 for _ in walk(cfg))} keys checked against the binary")
    return findings


# ---------------------------------------------------------------------- driver

SURFACES = {"themes": audit_themes, "settings": audit_settings}


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--surface", choices=sorted(SURFACES), action="append")
    ap.add_argument("--strings", type=Path, help="cache path for the binary strings dump")
    args = ap.parse_args()

    strings = binary_strings(args.strings)
    findings: list[str] = []
    for name in args.surface or sorted(SURFACES):
        findings += SURFACES[name](strings)

    if not findings:
        print("\nclean -- every surface matches the installed binary's schema")
        return 0
    print(f"\n{len(findings)} finding(s):")
    for f in findings:
        print(f"  - {f}")
    return 1


if __name__ == "__main__":
    sys.exit(main())
