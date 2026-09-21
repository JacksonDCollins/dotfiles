export NVIM_APPNAME=jc-nvim
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
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init --cmd cd bash)"
fi
shopt -s dotglob
export DOTFILES="$HOME/dotfiles"
if [[ -d $HOME/tmux-bins/tsm/bin && ":$PATH:" != *":$HOME/tmux-bins/tsm/bin:"* ]]; then
    export PATH="$HOME/tmux-bins/tsm/bin:$PATH"
fi
alias vimdiff='nvim -d'
if command -v fastfetch >/dev/null 2>&1; then
    fastfetch
fi
if [[ -f "$HOME/.cargo/env" ]]; then
    source "$HOME/.cargo/env"
fi
