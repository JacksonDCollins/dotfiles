#!/usr/bin/env bash
tmux list-sessions -F $'session\t#{session_name}\t#{SESSIONIZER_IDX}' >>"$1"
