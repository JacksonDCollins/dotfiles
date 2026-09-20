#!/usr/bin/env bash
source "$TMUX_PLUGIN_MANAGER_PATH/tmux-resurrect/scripts/helpers.sh"

while IFS=$'\t' read -r type session_name session_idx; do
        [ "$type" = "session" ] && tmux setenv -t "$session_name" SESSIONIZER_IDX "$session_idx"
done <"$(last_resurrect_file)"
