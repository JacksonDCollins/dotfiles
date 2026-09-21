#!/usr/bin/env bash
# Install Arch/CachyOS configuration dependencies, then apply dotfiles as the user.
set -euo pipefail
repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
(( EUID != 0 )) || { echo 'Run as your regular user; sudo is used only for pacman.' >&2; exit 1; }
(( $# <= 1 )) || { echo 'Usage: bash setup.sh [profile]' >&2; exit 1; }
profile=${1:-default}
[[ "$profile" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ && -d "$repo/machines/$profile" ]] || {
    echo 'Invalid machine profile.' >&2; exit 1;
}
command -v pacman >/dev/null || { echo 'Automatic dependencies require Arch/CachyOS. On other systems install equivalents, then run install.sh.' >&2; exit 1; }
mapfile -t packages < "$repo/packages-arch.txt"
(( ${#packages[@]} )) || { echo 'Empty dependency list.' >&2; exit 1; }
for package in "${packages[@]}"; do
    [[ "$package" =~ ^[a-z0-9][a-z0-9@._+-]*$ ]] || { echo 'Invalid dependency package name.' >&2; exit 1; }
done
# Stow is bootstrap infrastructure, not a configuration-specific dependency.
if ! pacman -Q -- stow "${packages[@]}" >/dev/null 2>&1; then
    sudo pacman -Syu --needed -- stow "${packages[@]}"
fi
bash "$repo/install.sh" "$profile"
bash "$repo/install-runtimes.sh"
