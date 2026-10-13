[[ -o interactive ]] || return

# Keep PATH entries unique across nested shells.
typeset -U path
path+=("$HOME/.local/bin")
if [[ -d $HOME/tmux-bins/tsm/bin ]]; then
    path=("$HOME/tmux-bins/tsm/bin" $path)
fi
export PATH
export DOTFILES="$HOME/dotfiles"
export EDITOR=nvim
export VISUAL=nvim
export SUDO_EDITOR=nvim
setopt GLOB_DOTS
alias vimdiff='nvim -d'

HISTSIZE=10000
SAVEHIST=10000
unsetopt SHARE_HISTORY INC_APPEND_HISTORY_TIME
setopt APPEND_HISTORY INC_APPEND_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE

# Use a fresh history context when sourcing this file in an existing shell too.
if [[ -n ${TMUX:-} && -n ${TMUX_PANE:-} ]]; then
    if _pane_history=$(bash "$HOME/tmux-bins/tmux-session-fixes/history.sh" init); then
        if [[ ${HISTFILE:-} != "$_pane_history" ]]; then
            fc -p "$_pane_history" "$HISTSIZE" "$SAVEHIST"
        fi
    else
        unset HISTFILE
        print -u2 'Could not initialize pane history; not falling back to shared history.'
    fi
    unset _pane_history
else
    HISTFILE="$HOME/.zsh_history"
fi

bindkey -e
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[OA' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search
bindkey '^[OB' down-line-or-beginning-search
# Deja wraps forward-word to accept a suggestion word. Keep Ctrl+Right for tmux.
bindkey '^[[1;3C' forward-word

autoload -Uz edit-command-line
zle -N edit-command-line
zstyle ':zle:edit-command-line' editor nvim
bindkey -r '^X' # Remove Deja's old single-key toggle when reloading.
bindkey '^X^E' edit-command-line

autoload -Uz compinit
compinit
zmodload zsh/complist
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' menu select=1

# Use fzf's pane-local history widget without its file/directory bindings.
if (( $+commands[fzf] )) && [[ -r /usr/share/fzf/key-bindings.zsh ]]; then
    FZF_CTRL_T_COMMAND='' FZF_ALT_C_COMMAND='' source /usr/share/fzf/key-bindings.zsh
fi

if [[ ${TERM:-} != dumb ]] && command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
else
    PROMPT='%n@%m:%~%# '
fi

if command -v fastfetch >/dev/null 2>&1; then
    # Preserve existing pane output, including scrollback replayed by Resurrect.
    if [[ -z ${TMUX:-} || -z ${TMUX_PANE:-} ]] ||
        ! tmux capture-pane -p -S - -t "$TMUX_PANE" 2>/dev/null | grep '[^[:space:]]' >/dev/null; then
        fastfetch
    fi
fi
# mise owns language runtimes, including Rust; do not override it with ~/.cargo/env.
if command -v mise >/dev/null 2>&1; then
    eval "$(mise activate zsh)"
fi
# Initialize last so mise cannot replace zoxide's cd function.
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init --cmd cd zsh)"
fi

# Plugins load after shell integrations; syntax highlighting must be last.
if [[ -r "$HOME/.config/zsh/plugins.zsh" ]]; then
    source "$HOME/.config/zsh/plugins.zsh" load
fi

# Return to the browsed directory when nnn exits.
n() {
    [ "${NNNLVL:-0}" -eq 0 ] || {
        echo "nnn is already running"
        return
    }

    # Use the terminal's themed palette instead of fixed xterm colours.
    export NNN_COLORS='#0404040404040404;44444444'
    export NNN_FCOLORS='030304020005060f01030501'
    export NNN_OPENER=/usr/share/nnn/plugins/nuke

    [[ -x "$HOME/.local/bin/nnn-dotfiles" ]] || {
        print -u2 'Build the configured nnn with: bash ~/dotfiles/scripts/install-nnn.sh'
        return 1
    }
    local -x NNN_TMPFILE
    NNN_TMPFILE=$(mktemp "${TMPDIR:-/tmp}/nnn-lastd.XXXXXXXXXX") || return 1
    NNN_TMPFILE=${NNN_TMPFILE:A}
    {
        command "$HOME/.local/bin/nnn-dotfiles" -c -d -D -H -Q -R "$@"
        [[ ! -s "$NNN_TMPFILE" ]] || source "$NNN_TMPFILE"
    } always {
        rm -f -- "$NNN_TMPFILE"
    }
}
