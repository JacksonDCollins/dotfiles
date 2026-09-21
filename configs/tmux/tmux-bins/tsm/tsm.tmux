#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TSM_EXECUTABLE="$CURRENT_DIR/bin/tsm"

tmux_option_or_fallback() {
        local option_value
        option_value="$(tmux show-option -gqv "$1")"
        if [ -z "$option_value" ]; then
                option_value="$2"
        fi
        echo "$option_value"
}

set_tsm_key_bindings() {
        #            
        tmux bind-key -n -N "Open session manager" "" run-shell "$TSM_EXECUTABLE"           # C-S-.
        tmux bind-key -n -N "Mark current session" "" run-shell "$TSM_EXECUTABLE mark add"  # C-S-0
        tmux bind-key -n -N "Manage marked sessions" "" run-shell "$TSM_EXECUTABLE mark list" # C-S--
        tmux bind-key -n -N "Switch to marked session 1" "" run-shell "$TSM_EXECUTABLE 1"     # C-S-1
        tmux bind-key -n -N "Switch to marked session 2" "" run-shell "$TSM_EXECUTABLE 2"     # C-S-2
        tmux bind-key -n -N "Switch to marked session 3" "" run-shell "$TSM_EXECUTABLE 3"     # C-S-3
        tmux bind-key -n -N "Switch to marked session 4" "" run-shell "$TSM_EXECUTABLE 4"     # C-S-4
        tmux bind-key -n -N "Switch to marked session 5" "" run-shell "$TSM_EXECUTABLE 5"     # C-S-5
        tmux bind-key -n -N "Switch to marked session 6" "" run-shell "$TSM_EXECUTABLE 6"     # C-S-6
        tmux bind-key -n -N "Switch to marked session 7" "" run-shell "$TSM_EXECUTABLE 7"     # C-S-7
        tmux bind-key -n -N "Switch to marked session 8" "" run-shell "$TSM_EXECUTABLE 8"     # C-S-8
        tmux bind-key -n -N "Switch to marked session 9" "" run-shell "$TSM_EXECUTABLE 9"     # C-S-9
}

get_session_name_cmd() {
        # Resolve format strings at script time (they're based on config, not session state)
        local status_active
        local status_inactive
        status_active="$(tmux display-message -p "$(tmux_option_or_fallback "@t-status-active" "#[fg=default,bg=default]")")"
        status_inactive="$(tmux display-message -p "$(tmux_option_or_fallback "@t-status-inactive" "#[fg=default,bg=default]")")"
        local idx="$1"

        # CRITICAL: Cannot use #{...} format variables inside #() because they get evaluated
        # in the current session context. Must use external script with literal tmux output.
        # Three-way logic:
        # 1. If session exists AND is current -> show ACTIVE (highlighted)
        # 2. If session exists AND is NOT current -> show INACTIVE (dimmed)
        # 3. If session doesn't exist -> show nothing
        local dynamic_cmd="current=\$(tmux show-environment SESSIONIZER_IDX 2>/dev/null | cut -d= -f2); found=\$($CURRENT_DIR/check-session-idx.sh $idx); if [[ \$found -eq 1 ]]; then if [[ \"\$current\" == \"$idx\" ]]; then echo '${status_active}${idx}'; else echo '${status_inactive}${idx}'; fi; fi"

        echo "$dynamic_cmd"
}
set_status_bar() {
        # Build the status-right string with dynamic #() commands
        local status_right_content=""
        for i in {1..9}; do
                local cmd="$(get_session_name_cmd "$i")"
                status_right_content="${status_right_content} #($cmd)"
        done

        # Ensure status-right-length is large enough for all the commands
        tmux set-option -g status-right-length 3500

        # Get the existing @tmux-dotbar-status-right value
        local dotbar_status_right="$(tmux_option_or_fallback "@tmux-dotbar-status-right" "")"

        # Append TSM session list to the dotbar status-right option
        # This way, when dotbar plugin runs (via TPM), it will include our session list
        tmux set-option -g @tmux-dotbar-status-right "${dotbar_status_right} |${status_right_content}"
}

main() {
        set_tsm_key_bindings
        set_status_bar
}
main
