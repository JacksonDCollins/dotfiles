#!/bin/bash
set -e

usage() {
    printf 'Usage: %s [machine]\n' "${0##*/}" >&2
}

if (($# > 1)); then
    usage
    exit 2
fi

MACHINE="${1-default}"
if [[ ! $MACHINE =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]]; then
    printf "Error: Invalid machine name '%s'\n" "$MACHINE" >&2
    usage
    exit 2
fi

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
if [[ -z ${HOME:-} || $HOME != /* || $HOME == / ]]; then
    printf "Error: HOME must be an absolute user directory, got '%s'\n" "${HOME:-}" >&2
    exit 2
fi
HOME=${HOME%/}
resolved_home=$(realpath -m -- "$HOME")
normalized_home=$(realpath -ms -- "$HOME")
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
RESTORE_SUFFIX="dotfiles-uninstall-$(date +%Y%m%d%H%M%S)-$$"
MODIFIED_CREATED=()
CREATED_DIRECTORIES=()

if [ -r "$MACHINE_STATE" ]; then
    IFS= read -r installed_machine <"$MACHINE_STATE"
    if [[ $installed_machine =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]]; then
        if (($# == 1)) && [ "$MACHINE" != "$installed_machine" ]; then
            printf 'Using installed machine %s instead of requested machine %s\n' "$installed_machine" "$MACHINE"
        fi
        MACHINE="$installed_machine"
    fi
fi

unstow_from() {
    local dir="$1"
    local package
    local packages=()

    for package in "$dir"/*; do
        [ -d "$package" ] || continue
        packages+=("${package##*/}")
    done

    [ "${#packages[@]}" -gt 0 ] || return 0
    stow --delete --dir "$dir" --target "$HOME" --verbose "${packages[@]}"
}

validate_recorded_path() {
    local target="$1"
    local parent resolved_parent

    parent=$(dirname -- "$target")
    resolved_parent=$(realpath -m -- "$parent")
    if [[ $resolved_parent != "$resolved_home" && $resolved_parent != "$resolved_home/"* ]]; then
        printf 'Error: Recorded path %s has a parent outside HOME\n' "$target" >&2
        return 1
    fi
    while [ "$parent" != "$HOME" ]; do
        if [ -L "$parent" ]; then
            printf 'Error: Refusing parent symlink %s while removing %s\n' "$parent" "$target" >&2
            return 1
        fi
        parent=$(dirname -- "$parent")
    done
}

validate_recorded_directory() {
    local directory="$1"
    local normalized

    normalized=$(realpath -ms -- "$directory")
    if [[ $normalized != "$normalized_home/"* ]]; then
        printf 'Error: Recorded directory is outside HOME: %s\n' "$directory" >&2
        return 1
    fi
}

validate_manifests() {
    local target backup

    for target in \
        "$HOME/.bashrc" \
        "$HOME/.config/foot/foot.ini" \
        "$HOME/.config/tmux/tmux.conf" \
        "$HOME/.config/hypr/hyprland.lua" \
        "$HOME/.config/omarchy/shell.json"; do
        validate_recorded_path "$target"
    done
    if [ -f "$LINK_MANIFEST" ]; then
        while IFS=$'\t' read -r target _; do
            validate_recorded_path "$target"
        done <"$LINK_MANIFEST"
    fi
    if [ -f "$CREATED_MANIFEST" ]; then
        while IFS=$'\t' read -r target _; do
            validate_recorded_path "$target"
        done <"$CREATED_MANIFEST"
    fi
    if [ -f "$DIRECTORY_MANIFEST" ]; then
        while IFS= read -r target; do
            validate_recorded_directory "$target"
        done <"$DIRECTORY_MANIFEST"
    fi
    if [ -f "$BACKUP_MANIFEST" ]; then
        while IFS=$'\t' read -r target backup _; do
            validate_recorded_path "$target"
            validate_recorded_path "$backup"
        done <"$BACKUP_MANIFEST"
    fi
}

remove_recorded_links() {
    local target source

    [ -f "$LINK_MANIFEST" ] || return 0
    while IFS=$'\t' read -r target source; do
        if
            [ -L "$target" ] &&
                [ "$(realpath -m -- "$target")" = "$(realpath -m -- "$source")" ]
        then
            rm -f -- "$target"
        fi
    done <"$LINK_MANIFEST"
}

move_current_aside() {
    local target="$1"
    local destination="$target-$RESTORE_SUFFIX"

    if [ -e "$destination" ] || [ -L "$destination" ]; then
        printf 'Error: Refusing to overwrite preserved file %s\n' "$destination" >&2
        return 1
    fi
    printf 'Moving current %s to %s\n' "$target" "$destination"
    mv -T -- "$target" "$destination"
}

remove_unchanged_created() {
    local target expected checksum

    [ -f "$CREATED_MANIFEST" ] || return 0
    while IFS=$'\t' read -r target expected; do
        if [ -e "$target" ] || [ -L "$target" ]; then
            if [ -n "$expected" ] && [ -f "$target" ] && [ ! -L "$target" ]; then
                checksum=$(sha256sum -- "$target")
                if [ "${checksum%% *}" = "$expected" ]; then
                    rm -f -- "$target"
                    continue
                fi
            fi
            MODIFIED_CREATED+=("$target")
        fi
    done <"$CREATED_MANIFEST"
}

remove_unchanged_replacements() {
    local target backup expected checksum

    [ -f "$BACKUP_MANIFEST" ] || return 0
    while IFS=$'\t' read -r target backup expected; do
        if [ -n "$expected" ] && [ "$expected" != - ] && [ -f "$target" ] && [ ! -L "$target" ]; then
            checksum=$(sha256sum -- "$target")
            if [ "${checksum%% *}" = "$expected" ]; then
                rm -f -- "$target"
            fi
        fi
    done <"$BACKUP_MANIFEST"
}

preserve_modified_created() {
    local target

    for target in "${MODIFIED_CREATED[@]}"; do
        if [ -e "$target" ] || [ -L "$target" ]; then
            move_current_aside "$target"
        fi
    done
}

load_created_directories() {
    local dir

    [ -f "$DIRECTORY_MANIFEST" ] || return 0
    while IFS= read -r dir; do
        CREATED_DIRECTORIES+=("$dir")
    done <"$DIRECTORY_MANIFEST"
}

remove_created_directories() {
    local dir pass

    for ((pass = ${#CREATED_DIRECTORIES[@]}; pass > 0; pass--)); do
        for dir in "${CREATED_DIRECTORIES[@]}"; do
            rmdir -- "$dir" 2>/dev/null || true
        done
    done
}

restore_backups() {
    local target backup

    [ -f "$BACKUP_MANIFEST" ] || return 0
    while IFS=$'\t' read -r target backup _; do
        if [ -e "$backup" ] || [ -L "$backup" ]; then
            if [ -e "$target" ] || [ -L "$target" ]; then
                move_current_aside "$target"
            fi
            mkdir -p -- "$(dirname -- "$target")"
            printf 'Restoring %s from %s\n' "$target" "$backup"
            mv -- "$backup" "$target"
        fi
    done <"$BACKUP_MANIFEST"
}

if ! command -v stow >/dev/null 2>&1; then
    printf '%s\n' 'Error: stow is not installed. Please install it first.'
    exit 1
fi

if [ ! -d "$REPO_ROOT/machines/$MACHINE" ] && [ ! -f "$LINK_MANIFEST" ]; then
    printf "Error: Machine configuration '%s' not found\n" "$MACHINE" >&2
    exit 1
fi

validate_manifests
load_created_directories

printf '%s\n' 'Uninstalling dotfiles...'

remove_unchanged_created
remove_unchanged_replacements

printf 'Removing machine-specific configs for: %s\n' "$MACHINE"
unstow_from "$REPO_ROOT/machines/$MACHINE"

printf '%s\n' 'Removing configs'
unstow_from "$REPO_ROOT/configs"

remove_recorded_links
preserve_modified_created
restore_backups
rm -f -- "$BACKUP_MANIFEST" "$CREATED_MANIFEST" "$DIRECTORY_MANIFEST" "$LINK_MANIFEST" "$MACHINE_STATE"
remove_created_directories

printf '%s\n' 'Uninstall complete!'
