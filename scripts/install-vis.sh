#!/usr/bin/env bash
# Install the fork package; pacman owns its runtime and dependencies.
set -euo pipefail
(( EUID != 0 )) || { echo 'Run as your regular user; makepkg uses sudo for pacman.' >&2; exit 1; }
(( $# == 0 )) || { echo 'Usage: scripts/install-vis.sh' >&2; exit 1; }
command -v pacman >/dev/null || { echo 'This installer requires Arch/CachyOS.' >&2; exit 1; }

if ! pacman -Q vis-retained-terminal >/dev/null 2>&1; then
    repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
    fork="$repo/../vis"
    command -v makepkg >/dev/null || { echo 'Install the Arch base-devel toolchain first.' >&2; exit 1; }
    if [[ ! -e "$fork" && ! -L "$fork" ]]; then
        git clone --branch retained-terminal --single-branch -- \
            https://github.com/JacksonDCollins/vis.git "$fork"
    fi
    [[ -f "$fork/PKGBUILD" && -f "$fork/vis-terminal.c" ]] || {
        echo "Expected the vis fork with PKGBUILD at $fork; existing paths are not replaced." >&2
        exit 1
    }
    (
        cd -- "$fork"
        makepkg --syncdeps --install --force
    )
fi

pacman -Q vis-retained-terminal
/usr/bin/vis -v
