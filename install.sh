#!/bin/bash
set -e

usage() {
        printf 'Usage: %s [machine]\n' "${0##*/}" >&2
}

if (( $# > 1 )); then
        usage
        exit 2
fi

MACHINE="${1-default}"
if [[ ! $MACHINE =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]]; then
        printf "Error: Invalid machine name '%s'\n" "$MACHINE" >&2
        usage
        exit 2
fi

BACKUP_SUFFIX="dotfiles-$(date +%Y%m%d%H%M%S)-$$"
REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
STOW_DIRS=("$REPO_ROOT/all" "$REPO_ROOT/linux" "$REPO_ROOT/machines/$MACHINE")
if [[ -z ${HOME:-} || $HOME != /* || $HOME == / ]]; then
        printf "Error: HOME must be an absolute user directory, got '%s'\n" "${HOME:-}" >&2
        exit 2
fi
HOME=${HOME%/}
resolved_home=$(realpath -m -- "$HOME")
if [[ $resolved_home == "$REPO_ROOT" || $resolved_home == "$REPO_ROOT/"* ]]; then
        printf 'Error: HOME must not resolve inside the dotfiles repository\n' >&2
        exit 2
fi
STATE_DIR="$HOME/.local/state/dotfiles"
BACKUP_MANIFEST="$STATE_DIR/backups.tsv"
CREATED_MANIFEST="$STATE_DIR/created"
DIRECTORY_MANIFEST="$STATE_DIR/directories"
LINK_MANIFEST="$STATE_DIR/links.tsv"
MACHINE_STATE="$STATE_DIR/machine"
declare -A MANAGED_TARGETS=()
declare -A SNAPSHOTTED_PATHS=()
declare -A RECORDED_MISSING_DIRS=()
MISSING_DIRS=()
SNAPSHOT_COUNT=0
TRANSACTION_ACTIVE=0

is_repo_path() {
        local resolved
        resolved=$(realpath -m -- "$1")
        [[ $resolved == "$REPO_ROOT" || $resolved == "$REPO_ROOT/"* ]]
}

is_repo_link() {
        [ -L "$1" ] && is_repo_path "$1"
}

validate_target() {
        local target="$1"
        local parent resolved_parent

        parent=$(dirname -- "$target")
        resolved_parent=$(realpath -m -- "$parent")
        if [[ $resolved_parent != "$resolved_home" && $resolved_parent != "$resolved_home/"* ]]; then
                printf 'Error: Target %s has a parent outside HOME\n' "$target" >&2
                return 1
        fi
        while [ "$parent" != "$HOME" ]; do
                if [ -L "$parent" ]; then
                        printf 'Error: Refusing parent symlink %s while installing %s\n' "$parent" "$target" >&2
                        return 1
                elif [ -e "$parent" ] && [ ! -d "$parent" ]; then
                        printf 'Error: Parent path %s is not a directory\n' "$parent" >&2
                        return 1
                fi
                parent=$(dirname -- "$parent")
        done
}

backup_target() {
        local target="$1"
        local backup="$target-$BACKUP_SUFFIX"
        local recorded

        while IFS=$'\t' read -r recorded _; do
                if [ "$recorded" = "$target" ]; then
                        printf 'Error: %s replaced a managed target whose original backup is already tracked\n' "$target" >&2
                        printf '%s\n' 'Move or remove it before reinstalling to avoid an orphaned backup.' >&2
                        return 1
                fi
        done <"$NEXT_BACKUP_MANIFEST"
        if [ -e "$backup" ] || [ -L "$backup" ]; then
                printf 'Error: Refusing to overwrite backup path %s\n' "$backup" >&2
                return 1
        fi
        printf 'Moving %s to %s\n' "$target" "$backup"
        printf '%s\t%s\n' "$target" "$backup" >>"$TRANSACTION_BACKUPS"
        mv -- "$target" "$backup"

        printf '%s\t%s\tpending\n' "$target" "$backup" >>"$NEXT_BACKUP_MANIFEST"
}

record_created() {
        local target="$1"
        local recorded hash found=0
        local updated="$TRANSACTION_DIR/created.updated"

        : >"$updated"
        while IFS=$'\t' read -r recorded hash; do
                if [ "$recorded" = "$target" ]; then
                        printf '%s\tpending\n' "$recorded" >>"$updated"
                        found=1
                else
                        printf '%s\t%s\n' "$recorded" "$hash" >>"$updated"
                fi
        done <"$NEXT_CREATED_MANIFEST"
        ((found)) || printf '%s\tpending\n' "$target" >>"$updated"
        mv -- "$updated" "$NEXT_CREATED_MANIFEST"
}

is_tracked_backup() {
        local target="$1"
        local recorded

        while IFS=$'\t' read -r recorded _; do
                [ "$recorded" = "$target" ] && return 0
        done <"$NEXT_BACKUP_MANIFEST"
        return 1
}

is_tracked_created() {
        local target="$1"
        local recorded

        while IFS=$'\t' read -r recorded _; do
                [ "$recorded" = "$target" ] && return 0
        done <"$NEXT_CREATED_MANIFEST"
        return 1
}

mark_backup_pending() {
        local target="$1"
        local recorded backup hash found=0
        local updated="$TRANSACTION_DIR/backups.updated"

        : >"$updated"
        while IFS=$'\t' read -r recorded backup hash; do
                if [ "$recorded" = "$target" ]; then
                        printf '%s\t%s\tpending\n' "$recorded" "$backup" >>"$updated"
                        found=1
                else
                        printf '%s\t%s\t%s\n' "$recorded" "$backup" "$hash" >>"$updated"
                fi
        done <"$NEXT_BACKUP_MANIFEST"
        if (( ! found )); then
                rm -f -- "$updated"
                return 1
        fi
        mv -- "$updated" "$NEXT_BACKUP_MANIFEST"
}

finalize_created_hashes() {
        local target hash checksum
        local finalized="$TRANSACTION_DIR/created.final"

        : >"$finalized"
        while IFS=$'\t' read -r target hash; do
                if [ -z "$hash" ] || [ "$hash" = pending ]; then
                        if [ ! -f "$target" ] || [ -L "$target" ]; then
                                printf 'Error: Created target is not a regular file: %s\n' "$target" >&2
                                return 1
                        fi
                        checksum=$(sha256sum -- "$target")
                        hash=${checksum%% *}
                fi
                printf '%s\t%s\n' "$target" "$hash" >>"$finalized"
        done <"$NEXT_CREATED_MANIFEST"
        mv -- "$finalized" "$NEXT_CREATED_MANIFEST"
}

finalize_backup_hashes() {
        local target backup hash checksum
        local finalized="$TRANSACTION_DIR/backups.final"

        : >"$finalized"
        while IFS=$'\t' read -r target backup hash; do
                if [ -z "$hash" ] || [ "$hash" = pending ]; then
                        if [ -f "$target" ] && [ ! -L "$target" ]; then
                                checksum=$(sha256sum -- "$target")
                                hash=${checksum%% *}
                        else
                                hash=-
                        fi
                fi
                printf '%s\t%s\t%s\n' "$target" "$backup" "$hash" >>"$finalized"
        done <"$NEXT_BACKUP_MANIFEST"
        mv -- "$finalized" "$NEXT_BACKUP_MANIFEST"
}

record_created_directories() {
        local dir recorded

        for dir in "${MISSING_DIRS[@]}"; do
                [ -d "$dir" ] && [ ! -L "$dir" ] || continue
                while IFS= read -r recorded; do
                        [ "$recorded" = "$dir" ] && continue 2
                done <"$NEXT_DIRECTORY_MANIFEST"
                printf '%s\n' "$dir" >>"$NEXT_DIRECTORY_MANIFEST"
        done
}

prepare_regular() {
        local target="$1"
        local template="$2"

        if [ -f "$target" ] && [ ! -L "$target" ]; then
                return 0
        elif [ -e "$target" ] || [ -L "$target" ]; then
                backup_target "$target"
        else
                record_created "$target"
        fi

        mkdir -p -- "$(dirname -- "$target")"
        cp -- "$template" "$target"
}

prepare_owned_regular() {
        local target="$1"
        local template="$2"
        local tracking=

        if is_tracked_backup "$target"; then
                tracking=backup
        elif is_tracked_created "$target"; then
                tracking=created
        elif [ -e "$target" ] || [ -L "$target" ]; then
                backup_target "$target"
                tracking=backup
        else
                record_created "$target"
                tracking=created
        fi

        if [ -e "$target" ] || [ -L "$target" ]; then
                if [ ! -f "$target" ] || [ -L "$target" ]; then
                        printf 'Error: Managed entrypoint is not a regular file: %s\n' "$target" >&2
                        return 1
                fi
                if cmp -s -- "$template" "$target"; then
                        if [ "$tracking" = backup ]; then
                                mark_backup_pending "$target"
                        else
                                record_created "$target"
                        fi
                        return 0
                fi
        fi

        mkdir -p -- "$(dirname -- "$target")"
        cp -- "$template" "$target"
        if [ "$tracking" = backup ]; then
                mark_backup_pending "$target"
        else
                record_created "$target"
        fi
}

record_missing_parents() {
        local parent

        parent=$(dirname -- "$1")
        while [ "$parent" != "$HOME" ]; do
                if [ ! -e "$parent" ] && [ ! -L "$parent" ] && [[ ! ${RECORDED_MISSING_DIRS[$parent]+present} ]]; then
                        RECORDED_MISSING_DIRS["$parent"]=1
                        MISSING_DIRS+=("$parent")
                fi
                parent=$(dirname -- "$parent")
        done
}

snapshot_path() {
        local target="$1"
        local snapshot

        [[ $target == "$HOME/"* ]] || return 1
        [[ ${SNAPSHOTTED_PATHS[$target]+present} ]] && return 0
        SNAPSHOTTED_PATHS["$target"]=1
        record_missing_parents "$target"
        SNAPSHOT_COUNT=$((SNAPSHOT_COUNT + 1))
        snapshot="$TRANSACTION_DIR/snapshots/$SNAPSHOT_COUNT"

        if [ -e "$target" ] || [ -L "$target" ]; then
                cp -a -- "$target" "$snapshot"
                printf '%s\tpresent\t%s\n' "$target" "$snapshot" >>"$SNAPSHOT_MANIFEST"
        else
                printf '%s\tabsent\n' "$target" >>"$SNAPSHOT_MANIFEST"
        fi
}

rollback_transaction() {
        local target status snapshot backup dir pass failed=0

        set +e
        printf '%s\n' 'Install failed; restoring the pre-install state' >&2
        while IFS=$'\t' read -r target status snapshot; do
                if [ "$status" = present ] && [ -f "$snapshot" ] && [ ! -L "$snapshot" ] && [ -f "$target" ] && [ ! -L "$target" ]; then
                        cp -a -- "$snapshot" "$target" || failed=1
                else
                        rm -rf -- "$target" || failed=1
                fi
                if [ "$status" = present ] && { [ ! -e "$target" ] || [ -L "$target" ]; }; then
                        mkdir -p -- "$(dirname -- "$target")" || failed=1
                        cp -a -- "$snapshot" "$target" || failed=1
                fi
        done <"$SNAPSHOT_MANIFEST"

        while IFS=$'\t' read -r target backup; do
                if [ -e "$backup" ] || [ -L "$backup" ]; then
                        rm -rf -- "$target" || failed=1
                        mv -T -- "$backup" "$target" || failed=1
                fi
        done <"$TRANSACTION_BACKUPS"

        for ((pass = ${#MISSING_DIRS[@]}; pass > 0; pass--)); do
                for dir in "${MISSING_DIRS[@]}"; do
                        rmdir -- "$dir" 2>/dev/null || true
                done
        done
        for dir in "${MISSING_DIRS[@]}"; do
                [ ! -d "$dir" ] || failed=1
        done

        if ((failed)); then
                printf 'Warning: rollback was incomplete; snapshots remain in %s\n' "$TRANSACTION_DIR" >&2
                KEEP_TRANSACTION=1
        fi
}

finish_transaction() {
        local exit_status=$?

        trap - EXIT INT TERM
        if ((exit_status != 0 && TRANSACTION_ACTIVE)); then
                rollback_transaction
        fi
        if [[ ! ${KEEP_TRANSACTION:-} ]]; then
                rm -rf -- "${TRANSACTION_DIR:-}"
        fi
        exit "$exit_status"
}

run_stow() {
        local dir="$1"
        local target="$2"
        local package
        local packages=()
        shift 2

        for package in "$dir"/*; do
                [ -d "$package" ] || continue
                packages+=("${package##*/}")
        done

        [ "${#packages[@]}" -gt 0 ] || return 0
        stow --no-folding --dir "$dir" --target "$target" "$@" "${packages[@]}"
}

stow_from() {
        local dir="$1"

        run_stow "$dir" "$HOME" --verbose
}

collect_staged_links() {
        local source relative target

        while IFS= read -r -d '' source; do
                relative=${source#"$TRANSACTION_DIR/preflight-home/"}
                target="$HOME/$relative"
                validate_target "$target"
                MANAGED_TARGETS["$target"]=1
                printf '%s\t%s\n' "$target" "$(realpath -m -- "$source")" >>"$NEW_LINK_MANIFEST"
        done < <(find "$TRANSACTION_DIR/preflight-home" -type l -print0)
}

record_staged_directories() {
        local source relative target

        while IFS= read -r -d '' source; do
                [ "$source" = "$TRANSACTION_DIR/preflight-home" ] && continue
                relative=${source#"$TRANSACTION_DIR/preflight-home/"}
                target="$HOME/$relative"
                validate_target "$target/.dotfiles-empty-directory"
                record_missing_parents "$target/.dotfiles-empty-directory"
        done < <(find "$TRANSACTION_DIR/preflight-home" -type d -empty -print0)
}

prepare_stow_targets() {
        local target source

        while IFS=$'\t' read -r target source; do
                if is_repo_link "$target"; then
                        [ "$(realpath -m -- "$target")" = "$(realpath -m -- "$source")" ] || rm -f -- "$target"
                elif [ -e "$target" ] || [ -L "$target" ]; then
                        backup_target "$target"
                fi
        done <"$NEW_LINK_MANIFEST"
}

remove_obsolete_links() {
        local target source

        [ -f "$LINK_MANIFEST" ] || return 0
        while IFS=$'\t' read -r target source; do
                if
                        [[ ! ${MANAGED_TARGETS[$target]+present} ]] &&
                                [ -L "$target" ] &&
                                [ "$(realpath -m -- "$target")" = "$(realpath -m -- "$source")" ]
                then
                        rm -f -- "$target"
                fi
        done <"$LINK_MANIFEST"
}

if ! command -v stow >/dev/null 2>&1; then
        printf '%s\n' 'Error: stow is not installed. Please install it first.'
        printf '%s\n' '  Ubuntu/Debian: sudo apt install stow'
        printf '%s\n' '  Arch: sudo pacman -S stow'
        exit 1
fi

if [ ! -d "$REPO_ROOT/machines/$MACHINE" ]; then
        printf "Error: Machine configuration '%s' not found\n" "$MACHINE" >&2
        printf '%s\n' 'Available machines:' >&2
        for machine_dir in "$REPO_ROOT"/machines/*; do
                [ -d "$machine_dir" ] && printf '  %s\n' "${machine_dir##*/}" >&2
        done
        exit 1
fi

OMARCHY_ROOT=${OMARCHY_PATH:-/usr/share/omarchy}
if [ ! -r "$OMARCHY_ROOT/default/bashrc" ]; then
        OMARCHY_ROOT=
fi
TMUX_CONFIG="$HOME/.config/tmux/tmux.conf"
tmux_template="$REPO_ROOT/templates/tmux.conf"

if [ -n "$OMARCHY_ROOT" ]; then
        bash_template="$OMARCHY_ROOT/default/bashrc"
        foot_template="$OMARCHY_ROOT/config/foot/foot.ini"
else
        bash_template="$REPO_ROOT/templates/bashrc"
        foot_template="$REPO_ROOT/templates/foot.ini"
fi

BASE_TARGETS=(
        "$HOME/.bashrc"
        "$HOME/.config/foot/foot.ini"
        "$TMUX_CONFIG"
)
BASE_TEMPLATES=("$bash_template" "$foot_template" "$tmux_template")
if [ -n "$OMARCHY_ROOT" ]; then
        for hypr_template in "$OMARCHY_ROOT"/config/hypr/*.lua; do
                [ -f "$hypr_template" ] || continue
                if [ "${hypr_template##*/}" = monitors.lua ] && [ -f "$REPO_ROOT/machines/$MACHINE/hypr/.config/hypr/monitors.lua" ]; then
                        continue
                fi
                BASE_TARGETS+=("$HOME/.config/hypr/${hypr_template##*/}")
                BASE_TEMPLATES+=("$hypr_template")
        done
fi

TRANSACTION_DIR=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-install.XXXXXX")
SNAPSHOT_MANIFEST="$TRANSACTION_DIR/snapshots.tsv"
TRANSACTION_BACKUPS="$TRANSACTION_DIR/new-backups"
NEXT_BACKUP_MANIFEST="$TRANSACTION_DIR/backups.tsv"
NEXT_CREATED_MANIFEST="$TRANSACTION_DIR/created"
NEXT_DIRECTORY_MANIFEST="$TRANSACTION_DIR/directories"
NEW_LINK_MANIFEST="$TRANSACTION_DIR/links.tsv"
NEXT_MACHINE_STATE="$TRANSACTION_DIR/machine"
TRANSACTION_TOKEN=${TRANSACTION_DIR##*.}
STATE_SOURCES=("$NEXT_BACKUP_MANIFEST" "$NEXT_CREATED_MANIFEST" "$NEXT_DIRECTORY_MANIFEST" "$NEW_LINK_MANIFEST" "$NEXT_MACHINE_STATE")
STATE_TARGETS=("$BACKUP_MANIFEST" "$CREATED_MANIFEST" "$DIRECTORY_MANIFEST" "$LINK_MANIFEST" "$MACHINE_STATE")
STATE_TEMPORARIES=()
for i in "${!STATE_TARGETS[@]}"; do
        STATE_TEMPORARIES+=("$STATE_DIR/.transaction-$TRANSACTION_TOKEN-$i")
done
mkdir -p -- "$TRANSACTION_DIR/snapshots" "$TRANSACTION_DIR/preflight-home"
touch -- "$SNAPSHOT_MANIFEST" "$TRANSACTION_BACKUPS" "$NEW_LINK_MANIFEST"
if [ -f "$BACKUP_MANIFEST" ]; then
        cp -- "$BACKUP_MANIFEST" "$NEXT_BACKUP_MANIFEST"
else
        touch -- "$NEXT_BACKUP_MANIFEST"
fi
if [ -f "$CREATED_MANIFEST" ]; then
        cp -- "$CREATED_MANIFEST" "$NEXT_CREATED_MANIFEST"
else
        touch -- "$NEXT_CREATED_MANIFEST"
fi
if [ -f "$DIRECTORY_MANIFEST" ]; then
        cp -- "$DIRECTORY_MANIFEST" "$NEXT_DIRECTORY_MANIFEST"
else
        touch -- "$NEXT_DIRECTORY_MANIFEST"
fi
printf '%s\n' "$MACHINE" >"$NEXT_MACHINE_STATE"
trap finish_transaction EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

for dir in "${STOW_DIRS[@]}"; do
        if ! run_stow "$dir" "$TRANSACTION_DIR/preflight-home" --simulate >"$TRANSACTION_DIR/stow-preflight.log" 2>&1; then
                cat "$TRANSACTION_DIR/stow-preflight.log" >&2
                exit 1
        fi
        run_stow "$dir" "$TRANSACTION_DIR/preflight-home"
done
collect_staged_links
record_staged_directories

for i in "${!BASE_TARGETS[@]}"; do
        validate_target "${BASE_TARGETS[$i]}"
        if [ ! -f "${BASE_TEMPLATES[$i]}" ] || [ ! -r "${BASE_TEMPLATES[$i]}" ]; then
                printf 'Error: Base template %s is not a readable file\n' "${BASE_TEMPLATES[$i]}" >&2
                exit 1
        fi
done

SHELL_CONFIG="$HOME/.config/omarchy/shell.json"
HOOK_TARGETS=(
        "$HOME/.bashrc"
        "$HOME/.config/foot/foot.ini"
        "$TMUX_CONFIG"
        "$HOME/.config/hypr/hyprland.lua"
        "$SHELL_CONFIG"
)
for target in "${HOOK_TARGETS[@]}"; do
        validate_target "$target"
done

FALLBACK_REMOVALS=()
if [ -z "$OMARCHY_ROOT" ]; then
        for target in "$HOME/.config/hypr/"*.lua; do
                if is_repo_link "$target" && [ ! -e "$target" ]; then
                        FALLBACK_REMOVALS+=("$target")
                fi
        done
fi

for target in "$BACKUP_MANIFEST" "$CREATED_MANIFEST" "$DIRECTORY_MANIFEST" "$LINK_MANIFEST" "$MACHINE_STATE"; do
        snapshot_path "$target"
done
for target in "${STATE_TEMPORARIES[@]}"; do
        if [ -e "$target" ] || [ -L "$target" ]; then
                printf 'Error: State transaction path already exists: %s\n' "$target" >&2
                exit 1
        fi
        snapshot_path "$target"
done
while IFS=$'\t' read -r target _; do
        [ -n "$target" ] && snapshot_path "$target"
done <"$NEW_LINK_MANIFEST"
if [ -f "$LINK_MANIFEST" ]; then
        while IFS=$'\t' read -r target _; do
                if [ -n "$target" ]; then
                        validate_target "$target"
                        snapshot_path "$target"
                fi
        done <"$LINK_MANIFEST"
fi
for target in "${BASE_TARGETS[@]}" "${HOOK_TARGETS[@]}" "${FALLBACK_REMOVALS[@]}"; do
        snapshot_path "$target"
done

TRANSACTION_ACTIVE=1
prepare_stow_targets
for dir in "${STOW_DIRS[@]}"; do
        stow_from "$dir"
done

remove_obsolete_links

for i in "${!BASE_TARGETS[@]}"; do
        if [ "${BASE_TARGETS[$i]}" = "$TMUX_CONFIG" ]; then
                prepare_owned_regular "${BASE_TARGETS[$i]}" "${BASE_TEMPLATES[$i]}"
        else
                prepare_regular "${BASE_TARGETS[$i]}" "${BASE_TEMPLATES[$i]}"
        fi
done

for target in "${FALLBACK_REMOVALS[@]}"; do
        is_repo_link "$target" && [ ! -e "$target" ] && rm -f -- "$target"
done

if [ -n "$OMARCHY_ROOT" ] &&
        [ -r "$OMARCHY_ROOT/config/omarchy/shell.json" ] &&
        [ -r "$HOME/.config/omarchy/plugins/jackson.workspaces/manifest.json" ] &&
        [ ! -e "$SHELL_CONFIG" ] && [ ! -L "$SHELL_CONFIG" ]; then
        record_created "$SHELL_CONFIG"
fi
bash "$HOME/.config/omarchy/hooks/post-update.d/zz-dotfiles-entrypoints"
finalize_created_hashes
finalize_backup_hashes

mkdir -p -- "$STATE_DIR"
record_created_directories
for i in "${!STATE_SOURCES[@]}"; do
        temporary=${STATE_TEMPORARIES[$i]}
        cp -- "${STATE_SOURCES[$i]}" "$temporary"
        mv -T -- "$temporary" "${STATE_TARGETS[$i]}"
done
TRANSACTION_ACTIVE=0

if command -v tmux >/dev/null 2>&1 && tmux list-sessions >/dev/null 2>&1; then
        tmux source-file "$HOME/.config/tmux/tmux.conf" || printf '%s\n' 'Warning: installed configs but could not reload tmux' >&2
fi
