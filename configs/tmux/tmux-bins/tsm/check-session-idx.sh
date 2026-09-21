#!/usr/bin/env bash
# Check if a session with the given SESSIONIZER_IDX exists
# Usage: check-session-idx.sh <idx>

idx="$1"
found=0

# Use tmux's literal output, not format variables
while IFS= read -r line; do
	# Extract session name from tmux output (format: session_name: ...)
	sess_name=$(echo "$line" | cut -d: -f1)
	# Get SESSIONIZER_IDX for this session
	sess_idx=$(tmux show-environment -t "$sess_name" SESSIONIZER_IDX 2>/dev/null | cut -d= -f2)
	if [[ "$sess_idx" == "$idx" ]]; then
		found=1
		break
	fi
done < <(tmux list-sessions 2>/dev/null)

echo "$found"
