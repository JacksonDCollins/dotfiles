#!/usr/bin/env bash
# Install missing plugins explicitly during setup, never when opening tmux.
set -euo pipefail
(( EUID != 0 )) || { echo 'Install tmux plugins as your regular user, not root.' >&2; exit 1; }
[[ ${HOME:-} == /* && $HOME != / ]] || { echo 'HOME must be an absolute user directory.' >&2; exit 1; }
for command in git tmux; do
    command -v "$command" >/dev/null || { echo "Install $command first (or run setup.sh)." >&2; exit 1; }
done
[[ -f "$HOME/.config/tmux/tmux.conf" ]] || { echo 'Apply dotfiles with install.sh first.' >&2; exit 1; }
plugins="$HOME/.config/tmux/plugins"
tpm="$plugins/tpm"
mkdir -p "$plugins"
if [[ ! -e "$tpm" && ! -L "$tpm" ]]; then
    GIT_TERMINAL_PROMPT=0 git clone -- https://github.com/tmux-plugins/tpm "$tpm"
fi
[[ -x "$tpm/bin/install_plugins" && -x "$tpm/tpm" ]] || {
    echo "Incomplete TPM checkout at $tpm; repair or move it aside and rerun setup." >&2
    exit 1
}

# TPM's CLI queries a tmux server for its plugin path. Give it a private server
# with no user config/session, so bootstrap cannot execute plugins or touch a live server.
workdir=$(mktemp -d /tmp/dotfiles-tpm.XXXXXX)
socket="$workdir/tmux.sock"
cleanup() {
    tmux -S "$socket" kill-server 2>/dev/null || true
    rm -rf -- "$workdir"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
tmux -S "$socket" -f /dev/null start-server \; set-option -g exit-empty off \; \
    set-environment -g TMUX_PLUGIN_MANAGER_PATH "$plugins/"
TMUX="$socket,0,0" XDG_CONFIG_HOME="$HOME/.config" "$tpm/bin/install_plugins"
