#!/usr/bin/env bash
# Run without modifying the real HOME or reloading the running desktop.
set -euo pipefail
repo=$(cd -- "$(dirname -- "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
export HOME="$tmp/home" XDG_CONFIG_HOME="$tmp/home/.config"
export XDG_RUNTIME_DIR="$tmp/runtime" TMUX_TMPDIR="$tmp/tmux"
export OMARCHY_PATH="$tmp/no-omarchy"
unset WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE TMUX
mkdir -p "$HOME/.config/hypr" "$XDG_RUNTIME_DIR" "$TMUX_TMPDIR"
chmod 700 "$XDG_RUNTIME_DIR"
configs=(.bashrc .config/foot/foot.ini .config/tmux/tmux.conf .config/hypr/hyprland.lua)
for config in "${configs[@]}"; do
    mkdir -p "$(dirname "$HOME/$config")"
    printf '%s\n' 'original config' > "$HOME/$config"
done
for profile in default default work jacktop default; do
    bash "$repo/install.sh" "$profile" > "$tmp/install.log" 2>&1 || { cat "$tmp/install.log"; exit 1; }
    for config in "${configs[@]}"; do
        [[ -L "$HOME/$config" ]]
    done
    [[ ! -e "$HOME/.local/bin/omarchy-agent-usage-openrouter" ]]
    [[ ! -e "$HOME/.config/bash/dotfiles.rc" ]]
    [[ ! -e "$HOME/.config/foot/dotfiles.ini" ]]
    [[ ! -e "$HOME/.config/tmux/dotfiles.conf" ]]
    [[ $(bash -c 'source "$HOME/.bashrc"; printf "%s" "$NVIM_APPNAME"') == jc-nvim ]]
    if command -v Hyprland >/dev/null; then
        Hyprland --verify-config -c "$HOME/.config/hypr/hyprland.lua" > "$tmp/hypr.log" 2>&1 || { cat "$tmp/hypr.log"; exit 1; }
    fi
done
bash "$repo/uninstall.sh" > "$tmp/uninstall.log" 2>&1 || { cat "$tmp/uninstall.log"; exit 1; }
for config in "${configs[@]}"; do
    [[ ! -L "$HOME/$config" && $(cat "$HOME/$config") == 'original config' ]]
done
printf '%s\n' 'PASS: install, profile switching, Hyprland validation (if available), and restore'
