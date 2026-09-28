#!/usr/bin/env bash
# Resurrect calls this after creating its pane-contents archive.
set -euo pipefail
umask 077
here=$(cd -- "$(dirname -- "$0")" && pwd)

if [[ ${1:-} == --member ]]; then
    # GNU tar streams regular files here, rather than extracting archive paths.
    name=${TAR_FILENAME#./}
    [[ ${TAR_FILETYPE:-} == f && $name == pane_contents/pane-* &&
        ${name#pane_contents/} != */* && $name != *$'\n'* && $name != *$'\r'* ]] || {
        echo 'Unexpected scrollback archive member.' >&2; exit 1;
    }
    set -o noclobber
    bash "$here/normalize-scrollback.sh" > "$SCROLLBACK_STAGE/$name"
    exit
fi

normalize_archive() (
    local archive=$1 work entry
    [[ -f "$archive" && ! -L "$archive" ]] || {
        echo 'Scrollback archive is missing or is a symlink; leaving it untouched.' >&2; exit 1;
    }
    work=$(mktemp -d "$(dirname -- "$archive")/.scrollback.XXXXXX")
    cleanup() {
        local result=$?
        rm -rf -- "$work"
        if (( result != 0 )); then echo 'Scrollback normalization failed; original archive retained.' >&2; fi
    }
    trap cleanup EXIT
    trap 'exit 130' INT
    trap 'exit 143' TERM
    cp -- "$archive" "$work/original.tar.gz"
    # Reject links/devices, which --to-command would otherwise silently skip.
    LC_ALL=C tar -tzvf "$work/original.tar.gz" > "$work/list"
    while IFS= read -r entry; do
        [[ $entry == [-d]* ]] || { echo 'Unsupported scrollback archive entry.' >&2; exit 1; }
    done < "$work/list"
    export SCROLLBACK_STAGE="$work/stage" SCROLLBACK_HELPER="$here/post-save.sh"
    mkdir -p "$SCROLLBACK_STAGE/pane_contents"
    tar -xzf "$work/original.tar.gz" --to-command='exec bash "$SCROLLBACK_HELPER" --member'
    tar -czf "$work/repaired.tar.gz" -C "$SCROLLBACK_STAGE" ./pane_contents
    # Do not knowingly overwrite another save's replacement. The final rename
    # is atomic because the temporary archive is on the same filesystem.
    [[ -f "$archive" && ! -L "$archive" ]] && cmp -s "$work/original.tar.gz" "$archive" || {
        echo 'Scrollback archive changed during processing.' >&2; exit 1;
    }
    mv -fT -- "$work/repaired.tar.gz" "$archive"
)

# Separate entrypoint for isolated checks or explicitly repairing an archive.
if [[ ${1:-} == --archive ]]; then
    (( $# == 2 )) || exit 2
    normalize_archive "$2"
    exit
fi

source "${TMUX_PLUGIN_MANAGER_PATH:-$HOME/.config/tmux/plugins/}/tmux-resurrect/scripts/helpers.sh"
if [[ $(tmux show-option -gqv @resurrect-capture-pane-contents) == on ]]; then
    normalize_archive "$(pane_contents_archive_file)"
fi
bash "$here/history.sh" gc
