#!/usr/bin/env bash
# Run after install.sh has Stowed the global mise config. Never run as root.
set -euo pipefail
(( EUID != 0 )) || { echo 'Install mise runtimes as the regular user, not root.' >&2; exit 1; }
command -v mise >/dev/null || { echo 'Install mise first (or run setup.sh).' >&2; exit 1; }
[[ -f "$HOME/.config/mise/config.toml" ]] || { echo 'Apply dotfiles with install.sh before installing runtimes.' >&2; exit 1; }
# Ignore the caller's project directory; install the user's global defaults.
mise --cd "$HOME" install --yes
mise --cd "$HOME" reshim

# Reconcile personal Pi packages using Pi's own package manager. Do not update
# the mise-pinned Pi binary or trust/install packages from the caller's project.
[[ -f "$HOME/.pi/agent/settings.json" ]] || { echo 'Apply the Pi config with install.sh first.' >&2; exit 1; }
PI_CODING_AGENT_DIR="$HOME/.pi/agent" mise --cd "$HOME" exec -- pi update --extensions --no-approve
