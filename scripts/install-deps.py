#!/usr/bin/env python3
"""Install or upgrade system packages from packages/*.txt lists.

Default mode reads package lists, skips already-installed packages, and only
prints output when there's actual work to do. Pass --upgrade to bump every
managed package to its latest version.

apt is intentionally skipped in --upgrade mode: a system-wide `apt upgrade`
is too broad to trigger from this script. Bump system packages with the OS's
own update flow.
"""

import argparse
import platform
import shutil
import subprocess
import sys
from pathlib import Path

PACKAGES_DIR = Path(__file__).resolve().parent.parent / "packages"


def read_package_list(filename: str) -> list[str]:
    """Read a package list file, stripping comments and blanks."""
    path = PACKAGES_DIR / filename
    if not path.exists():
        return []
    packages = []
    for line in path.read_text().splitlines():
        line = line.split("#", 1)[0].strip()
        if line:
            packages.append(line)
    return packages


def run(cmd: list[str], **kwargs) -> subprocess.CompletedProcess[str]:
    return subprocess.run(cmd, capture_output=True, text=True, **kwargs)


def brew_install(packages: list[str]) -> None:
    result = run(["brew", "list", "--formula"])
    installed = set(result.stdout.splitlines())

    missing = [p for p in packages if p not in installed]
    if not missing:
        return

    print(f"Installing brew packages: {', '.join(missing)}")
    proc = subprocess.run(["brew", "install", *missing])
    if proc.returncode != 0:
        print("Warning: some brew packages may have failed to install", file=sys.stderr)


def brew_upgrade(packages: list[str]) -> None:
    print(f"Upgrading brew packages: {', '.join(packages)}")
    subprocess.run(["brew", "upgrade", *packages])


def install_brew(upgrade: bool) -> None:
    if not shutil.which("brew"):
        print("brew not found — skipping brew packages")
        return
    packages = read_package_list("brew.txt")
    if not packages:
        return
    if upgrade:
        brew_upgrade(packages)
    else:
        brew_install(packages)


def install_apt(upgrade: bool) -> None:
    if upgrade:
        # System-wide upgrades are out of scope for this script.
        return
    if not shutil.which("apt"):
        print("apt not found — skipping apt packages")
        return

    packages = read_package_list("apt.txt")
    if not packages:
        return

    result = run(["dpkg", "-l", *packages])
    installed = set()
    for line in result.stdout.splitlines():
        if line.startswith("ii"):
            parts = line.split()
            if len(parts) >= 2:
                installed.add(parts[1])

    missing = [p for p in packages if p not in installed]
    if not missing:
        return

    print(f"Installing apt packages: {', '.join(missing)}")
    subprocess.run(["sudo", "apt", "install", "-y", *missing])


def luarocks_flags() -> list[str]:
    # --local installs into the user tree (~/.luarocks) instead of the system
    # tree (/opt/homebrew), which avoids sudo. Ensure ~/.luarocks/bin is on PATH.
    flags = ["--local"]
    if not shutil.which("brew"):
        return flags
    result = run(["brew", "--prefix", "lua@5.4"])
    lua_dir = result.stdout.strip()
    if lua_dir and Path(lua_dir).is_dir():
        flags.append(f"--lua-dir={lua_dir}")
    return flags


def install_luarocks(upgrade: bool) -> None:
    if not shutil.which("luarocks"):
        print("luarocks not found — skipping luarocks packages")
        return

    packages = read_package_list("luarocks.txt")
    if not packages:
        return

    flags = luarocks_flags()

    for pkg in packages:
        if upgrade:
            print(f"Upgrading luarock {pkg}...")
            subprocess.run(["luarocks", *flags, "install", "--force", pkg])
            continue
        check = run(["luarocks", *flags, "show", pkg])
        if check.returncode == 0:
            continue
        print(f"Installing luarock {pkg}...")
        subprocess.run(["luarocks", *flags, "install", pkg])


def cargo_installed() -> set[str]:
    """Return the set of crate names currently installed via cargo."""
    result = run(["cargo", "install", "--list"])
    return {
        line.split()[0]
        for line in result.stdout.splitlines()
        if line and not line.startswith(" ")
    }


def install_cargo(upgrade: bool) -> None:
    if not shutil.which("cargo"):
        print("cargo not found — skipping cargo packages")
        return

    packages = read_package_list("cargo.txt")
    if not packages:
        return

    if upgrade:
        if not shutil.which("cargo-install-update"):
            print("cargo-update not found — run 'make deps' first to bootstrap it")
            return
        print(f"Upgrading cargo packages: {', '.join(packages)}")
        subprocess.run(["cargo", "install-update", *packages])
        return

    installed = cargo_installed()

    # Bootstrap cargo-binstall first so the rest can install via prebuilt binaries.
    if "cargo-binstall" in packages and "cargo-binstall" not in installed:
        print("Installing cargo package cargo-binstall...")
        subprocess.run(["cargo", "install", "cargo-binstall"])

    has_binstall = shutil.which("cargo-binstall") is not None

    for pkg in packages:
        if pkg == "cargo-binstall" or pkg in installed:
            continue
        print(f"Installing cargo package {pkg}...")
        if has_binstall:
            subprocess.run(["cargo", "binstall", "-y", pkg])
        else:
            subprocess.run(["cargo", "install", pkg])


def uv_tool_installed() -> set[str]:
    """Return the set of tool names currently installed via `uv tool`."""
    result = run(["uv", "tool", "list"])
    return {
        line.split()[0]
        for line in result.stdout.splitlines()
        if line and not line.startswith(" ") and not line.startswith("-")
    }


def install_uv_tools(upgrade: bool) -> None:
    if not shutil.which("uv"):
        print("uv not found — skipping uv tool packages")
        return

    packages = read_package_list("uv-tools.txt")
    if not packages:
        return

    if upgrade:
        print(f"Upgrading uv tools: {', '.join(packages)}")
        subprocess.run(["uv", "tool", "upgrade", *packages])
        return

    installed = uv_tool_installed()
    missing = [p for p in packages if p not in installed]
    if not missing:
        return

    for pkg in missing:
        print(f"Installing uv tool {pkg}...")
        subprocess.run(["uv", "tool", "install", pkg])


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--upgrade",
        action="store_true",
        help="Bump managed packages to latest versions instead of installing missing ones.",
    )
    args = parser.parse_args()

    system = platform.system()

    if system == "Darwin":
        install_brew(args.upgrade)
    elif system == "Linux":
        install_apt(args.upgrade)

    install_luarocks(args.upgrade)
    install_cargo(args.upgrade)
    install_uv_tools(args.upgrade)


if __name__ == "__main__":
    main()
