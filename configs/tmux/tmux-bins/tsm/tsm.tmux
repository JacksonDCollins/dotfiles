#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TSM_EXECUTABLE="$CURRENT_DIR/bin/tsm"

set_tsm_key_bindings() {
        # Foot reports shifted US-layout symbols with Ctrl+Shift via modifyOtherKeys.
        tmux bind-key -n -N "Open session manager" 'C-S->' run-shell "$TSM_EXECUTABLE"           # C-S-.
        tmux bind-key -n -N "Mark current session" 'C-S-)' run-shell "$TSM_EXECUTABLE mark add"  # C-S-0
        tmux bind-key -n -N "Manage marked sessions" 'C-S-_' run-shell "$TSM_EXECUTABLE mark list" # C-S--
        tmux bind-key -n -N "Switch to marked session 1" 'C-S-!' run-shell "$TSM_EXECUTABLE 1"     # C-S-1
        tmux bind-key -n -N "Switch to marked session 2" 'C-S-@' run-shell "$TSM_EXECUTABLE 2"     # C-S-2
        tmux bind-key -n -N "Switch to marked session 3" 'C-S-#' run-shell "$TSM_EXECUTABLE 3"     # C-S-3
        tmux bind-key -n -N "Switch to marked session 4" 'C-S-$' run-shell "$TSM_EXECUTABLE 4"     # C-S-4
        tmux bind-key -n -N "Switch to marked session 5" 'C-S-%' run-shell "$TSM_EXECUTABLE 5"     # C-S-5
        tmux bind-key -n -N "Switch to marked session 6" 'C-S-^' run-shell "$TSM_EXECUTABLE 6"     # C-S-6
        tmux bind-key -n -N "Switch to marked session 7" 'C-S-&' run-shell "$TSM_EXECUTABLE 7"     # C-S-7
        tmux bind-key -n -N "Switch to marked session 8" 'C-S-*' run-shell "$TSM_EXECUTABLE 8"     # C-S-8
        tmux bind-key -n -N "Switch to marked session 9" 'C-S-(' run-shell "$TSM_EXECUTABLE 9"     # C-S-9
}

set_tsm_key_bindings
