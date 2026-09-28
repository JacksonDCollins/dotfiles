# Shared declarations for explicit installation and offline shell startup.
() {
    local mode=${1:-load}
    local manager="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git/zinit.zsh"
    if [[ ! -r "$manager" ]]; then
        [[ $mode == install ]] && return 1
        return 0
    fi
    typeset -gA ZINIT
    ZINIT[HOME_DIR]="${XDG_DATA_HOME:-$HOME/.local/share}/zinit"
    if (( ! $+functions[zinit] )); then
        source "$manager" || return
    fi

    # Deja's shared suggestion database is separate from per-pane HISTFILEs.
    # Leave Tab bound to native completion; Deja's arrow-key acceptance remains.
    export DEJA_CYCLE_KEY=''
    # Keep Ctrl+X a chord prefix for edit-command-line, not a timed toggle.
    export DEJA_TOGGLE_KEY='^X^X'
    local plugin version entry directory expected actual
    local -a declarations=(
        Giammarco-Ferranti/deja v0.4.2 deja.plugin.zsh
        zsh-users/zsh-syntax-highlighting 0.8.0 zsh-syntax-highlighting.zsh
    )
    for plugin version entry in "${declarations[@]}"; do
        directory="$ZINIT[PLUGINS_DIR]/${plugin//\//---}"
        if [[ $mode == install ]]; then
            zinit ice depth=1 cloneopts"--branch $version" ver"$version" pick"$entry" cloneonly
            zinit light "$plugin" || return
            [[ -r "$directory/$entry" ]] || return 1
            # Zinit can report success even when its checkout command failed.
            expected=$(git -C "$directory" rev-parse --verify "refs/tags/$version^{commit}" 2>/dev/null)
            actual=$(git -C "$directory" rev-parse --verify HEAD 2>/dev/null)
            if [[ -z "$expected" || "$actual" != "$expected" ]]; then
                print -ru2 -- "Plugin $plugin is not at $version. Repair $directory explicitly, then rerun setup."
                return 1
            fi
        elif [[ -r "$directory/$entry" ]]; then
            # Never ask Zinit to clone a missing plugin during startup.
            [[ $plugin == Giammarco-Ferranti/deja ]] && (( ! $+commands[deja] )) && continue
            zinit ice ver"$version" pick"$entry"
            zinit light "$plugin" || return
        fi
    done
} "$@"
