# Algothix OS (ALX) Lite — Lightweight Zsh configuration (FR-3.3)
# No heavy plugin frameworks; fast startup for 2 GB RAM hardware.

HISTFILE="${HOME}/.zsh_history"
HISTSIZE=5000
SAVEHIST=5000
setopt APPEND_HISTORY SHARE_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE

autoload -Uz compinit vcs_info
compinit -C

zstyle ':completion:*' menu select
zstyle ':vcs_info:git:*' formats ' (%b)'
precmd() { vcs_info; }

setopt PROMPT_SUBST
PROMPT='%F{cyan}%n@%m%f:%F{blue}%~%f%F{yellow}${vcs_info_msg_0_}%f %# '

# Sensible Debian tool aliases
alias ll='ls -alF --color=auto'
alias la='ls -A --color=auto'
alias l='ls -CF --color=auto'
alias grep='grep --color=auto'
alias gs='git status -sb'
command -v batcat >/dev/null 2>&1 && alias bat='batcat'
command -v fdfind >/dev/null 2>&1 && alias fd='fdfind'

# Enable fzf keybindings when available
[ -r /usr/share/doc/fzf/examples/key-bindings.zsh ] && source /usr/share/doc/fzf/examples/key-bindings.zsh

export EDITOR=nvim
export VISUAL=nvim
export PAGER="less -R"
