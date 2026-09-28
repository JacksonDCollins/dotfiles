#!/usr/bin/env bash
# Private histories are scoped to a stable tmux socket, not ephemeral pane IDs.
set -euo pipefail
umask 077

socket=$(tmux display-message -p '#{socket_path}')
[[ -n "$socket" ]] || exit 1
namespace=$(printf '%s' "$socket" | sha256sum)
root="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/panes/${namespace%% *}"
mkdir -p "$root"
exec 9>"$root/.lock"
flock -x 9

valid_id() { [[ "$1" =~ ^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$ ]]; }

remember_directory() {
    local directory
    directory=$(realpath -e -- "$1")
    [[ "$directory" != *$'\n'* ]] || return 1
    if ! grep -Fxq -- "$directory" "$root/.snapshot-directories" 2>/dev/null; then
        printf '%s\n' "$directory" >> "$root/.snapshot-directories"
    fi
}

load_resurrect() {
    source "${TMUX_PLUGIN_MANAGER_PATH:-$HOME/.config/tmux/plugins/}/tmux-resurrect/scripts/helpers.sh"
    remember_directory "$(resurrect_dir)"
}

collect_unused() {
    # No deletion while restore is constructing panes or assigning their IDs.
    [[ -z $(tmux show-option -gqv @history-restore-pid) ]] || return 0
    local live directory snapshot contents kind session window pane id extra file
    local -A retained=()
    live=$(tmux list-panes -a -F '#{@history-id}') || return 1
    while IFS= read -r id; do
        [[ -n "$id" ]] || continue
        valid_id "$id" || return 1
        retained["$id"]=1
    done <<< "$live"
    shopt -s nullglob
    while IFS= read -r directory; do
        # Missing paths may be inaccessible or temporarily unmounted, not deleted.
        [[ -d "$directory" && -r "$directory" && -x "$directory" ]] || {
            printf 'Pane history: cannot inspect snapshot directory %s; cleanup skipped.\n' "$directory" >&2
            return 1
        }
        for snapshot in "$directory"/*.txt "$directory"/last; do
            [[ -e "$snapshot" || -L "$snapshot" ]] || continue
            [[ -f "$snapshot" && -r "$snapshot" ]] || return 1
            contents=$(cat -- "$snapshot") || return 1
            # Old or incomplete snapshots cannot prove which histories they need.
            grep -Fxq $'history-version\t1' <<< "$contents" || return 0
            while IFS=$'\t' read -r kind session window pane id extra; do
                [[ "$kind" == history ]] || continue
                valid_id "$id" && [[ -z "$extra" ]] || return 1
                retained["$id"]=1
            done <<< "$contents"
        done
    done < "$root/.snapshot-directories"
    for file in "$root"/*.history; do
        id=${file##*/}; id=${id%.history}
        valid_id "$id" || continue
        [[ ${retained[$id]+yes} ]] || rm -- "$file"
    done
}

case "${1:-}" in
    init)
        # Resurrect creates shells before its post-restore hook. Wait before Zsh
        # reads any history; an interrupted restore must not block startup forever.
        for ((attempt=0; ; attempt++)); do
            owner=$(tmux show-option -gqv @history-restore-pid)
            [[ -n "$owner" ]] || break
            if [[ ! "$owner" =~ ^[0-9]+$ ]] || ! kill -0 "$owner" 2>/dev/null; then
                tmux set-option -gu @history-restore-pid
                break
            fi
            if (( attempt >= 600 )); then
                echo 'Pane history: restore did not finish; history disabled. Source ~/.zshrc after recovery.' >&2
                exit 1
            fi
            flock -u 9
            sleep 0.1
            flock -x 9
        done
        id=$(tmux show-option -pqv -t "$TMUX_PANE" @history-id)
        if [[ -z "$id" ]]; then
            id=$(< /proc/sys/kernel/random/uuid)
            tmux set-option -p -t "$TMUX_PANE" @history-id "$id"
        fi
        valid_id "$id" || exit 1
        touch -- "$root/$id.history"
        chmod 600 -- "$root/$id.history"
        printf '%s\n' "$root/$id.history"
        ;;
    save)
        remember_directory "$(dirname -- "$2")"
        records=$(tmux list-panes -a -F $'history\t#{session_name}\t#{window_index}\t#{pane_index}\t#{@history-id}')
        while IFS=$'\t' read -r kind session window pane id; do
            [[ -n "$id" ]] || continue
            valid_id "$id" || exit 1
            printf 'history\t%s\t%s\t%s\t%s\n' "$session" "$window" "$pane" "$id"
        done <<< "$records" >> "$2"
        printf 'history-version\t1\n' >> "$2"
        ;;
    pre-restore)
        # Called directly by Resurrect, so PPID is its restore process.
        tmux set-option -g @history-restore-pid "$PPID"
        ;;
    restore)
        trap 'tmux set-option -gu @history-restore-pid' EXIT
        load_resurrect
        while IFS=$'\t' read -r kind session window pane id extra; do
            [[ "$kind" == history ]] || continue
            valid_id "$id" && [[ -n "$session" && "$window" =~ ^[0-9]+$ && "$pane" =~ ^[0-9]+$ && -z "$extra" ]] || exit 1
            target="=$session:$window.$pane"
            current=$(tmux show-option -pqv -t "$target" @history-id) || exit 1
            # Resurrect can merge into a live server; never replace a live history.
            [[ -n "$current" ]] || tmux set-option -p -t "$target" @history-id "$id"
        done < "$(last_resurrect_file)"
        tmux set-option -gu @history-restore-pid
        trap - EXIT
        collect_unused
        ;;
    gc)
        load_resurrect
        collect_unused
        ;;
    *) echo 'Usage: history.sh init|save SNAPSHOT|pre-restore|restore|gc' >&2; exit 2 ;;
esac
