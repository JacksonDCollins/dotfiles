#!/usr/bin/env bash
# Install plugins explicitly, never while opening a shell.
set -euo pipefail
(( EUID != 0 )) || { echo 'Install Zsh plugins as the regular user, not root.' >&2; exit 1; }
[[ "$HOME" == /* ]] || { echo 'HOME must be an absolute path.' >&2; exit 1; }
for tool in git zsh mise; do
    command -v "$tool" >/dev/null || { echo "Install $tool first (or run setup.sh)." >&2; exit 1; }
done
[[ -f "$HOME/.config/zsh/plugins.zsh" ]] || { echo 'Apply dotfiles with install.sh first.' >&2; exit 1; }
zinit_home="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
if [[ ! -e "$zinit_home" && ! -L "$zinit_home" ]]; then
    mkdir -p -- "$(dirname -- "$zinit_home")"
    GIT_TERMINAL_PROMPT=0 git clone --depth 1 --branch v3.17.0 \
        https://github.com/zdharma-continuum/zinit.git "$zinit_home"
fi
[[ -d "$zinit_home/.git" && -r "$zinit_home/zinit.zsh" ]] || {
    echo "Incomplete Zinit checkout at $zinit_home; repair or move it aside and rerun setup." >&2; exit 1;
}
# Generate the cached integration, but do not source it, spawn its daemon, or
# import personal history during setup. mise owns the Deja binary version.
mise --cd "$HOME" exec -- deja init zsh >/dev/null
GIT_TERMINAL_PROMPT=0 zsh -dfc 'source "$HOME/.config/zsh/plugins.zsh" install'
