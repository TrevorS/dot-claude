#!/usr/bin/env python3
"""Install system packages from packages/*.txt lists.

Reads package lists, skips already-installed packages, and only prints
output when there's actual work to do.
"""

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


def install_brew():
    if not shutil.which("brew"):
        print("brew not found — skipping brew packages")
        return

    packages = read_package_list("brew.txt")
    if not packages:
        return

    # Check which packages are already installed
    result = run(["brew", "list", "--formula"])
    installed = set(result.stdout.splitlines())

    missing = [p for p in packages if p not in installed]
    if not missing:
        return

    print(f"Installing brew packages: {', '.join(missing)}")
    proc = subprocess.run(["brew", "install", *missing])
    if proc.returncode != 0:
        print("Warning: some brew packages may have failed to install", file=sys.stderr)


def install_apt():
    if not shutil.which("apt"):
        print("apt not found — skipping apt packages")
        return

    packages = read_package_list("apt.txt")
    if not packages:
        return

    # Check which packages are already installed via dpkg
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


def install_luarocks():
    if not shutil.which("luarocks"):
        print("luarocks not found — skipping luarocks packages")
        return

    packages = read_package_list("luarocks.txt")
    if not packages:
        return

    lr_flags: list[str] = []
    if shutil.which("brew"):
        result = run(["brew", "--prefix", "lua@5.4"])
        lua_dir = result.stdout.strip()
        if lua_dir and Path(lua_dir).is_dir():
            lr_flags = [f"--lua-dir={lua_dir}"]

    for pkg in packages:
        check = run(["luarocks", *lr_flags, "show", pkg])
        if check.returncode == 0:
            continue
        print(f"Installing luarock {pkg}...")
        subprocess.run(["sudo", "luarocks", *lr_flags, "install", pkg])


def install_cargo():
    if not shutil.which("cargo"):
        print("cargo not found — skipping cargo packages")
        return

    packages = read_package_list("cargo.txt")
    if not packages:
        return

    result = run(["cargo", "install", "--list"])
    installed_lines = result.stdout
    installed = {line.split()[0] for line in installed_lines.splitlines() if not line.startswith(" ") and line.strip()}

    has_binstall = shutil.which("cargo-binstall") is not None

    for pkg in packages:
        if pkg in installed:
            continue
        print(f"Installing cargo package {pkg}...")
        if has_binstall and pkg != "cargo-binstall":
            subprocess.run(["cargo", "binstall", "-y", pkg])
        else:
            subprocess.run(["cargo", "install", pkg])


def main():
    system = platform.system()

    if system == "Darwin":
        install_brew()
    elif system == "Linux":
        install_apt()

    install_luarocks()
    install_cargo()


if __name__ == "__main__":
    main()
