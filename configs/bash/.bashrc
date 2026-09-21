[[ $- == *i* ]] || return

if [[ ${TERM:-} != dumb ]] && command -v starship >/dev/null 2>&1; then
    eval "$(starship init bash)"
else
    PS1='\u@\h:\w\$ '
fi

case ":$PATH:" in
*":$HOME/.local/bin:"*) ;;
*) PATH="${PATH:+$PATH:}$HOME/.local/bin" ;;
esac
export PATH
shopt -s dotglob
export DOTFILES="$HOME/dotfiles"
if [[ -d $HOME/tmux-bins/tsm/bin && ":$PATH:" != *":$HOME/tmux-bins/tsm/bin:"* ]]; then
    export PATH="$HOME/tmux-bins/tsm/bin:$PATH"
fi
alias vimdiff='nvim -d'
if command -v fastfetch >/dev/null 2>&1; then
    fastfetch
fi
# mise owns language runtimes, including Rust; do not override it with ~/.cargo/env.
if command -v mise >/dev/null 2>&1; then
    eval "$(mise activate bash)"
fi
# Initialize last so mise cannot replace zoxide's cd function.
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init --cmd cd bash)"
fi
