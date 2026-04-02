# path (last prepend wins — user bins must come after system bins)
export PATH="/opt/homebrew/opt/sqlite/bin:$PATH"
export PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:$PATH"
export PATH="/opt/homebrew/bin:$PATH"
export PATH="$HOME/.cache/lm-studio/bin:$PATH"
export PATH="$HOME/go/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export MANPATH="/opt/homebrew/opt/coreutils/libexec/gnuman:$MANPATH"
export LIBRARY_PATH=/opt/homebrew/lib:$LIBRARY_PATH
export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_NO_ENV_HINTS=1
export HOMEBREW_NO_ANALYTICS=1
export HOMEBREW_BAT=1

# editor
export EDITOR="nvim"

# aliases
alias ls="ls --color=auto"
alias l="ls"
alias la="ls -la"
alias lah="ls -lah"
alias vim="nvim"
alias cat="${commands[bat]:-${commands[batcat]:-cat}}"
alias sed="gsed"
alias python=python3
alias pip=pip3

alias gst="git status"
alias gaa="git add --all"
alias gc="git commit --verbose"
alias gdc="git diff --cached"
alias gb="git branch"
alias gco="git checkout"
alias gcm="git checkout master"
alias gcd="git checkout dev"

alias cdc="cd $HOME/.claude"
alias cdp="cd $HOME/Projects"

alias dcu="docker compose up"
alias dcd="docker compose down"

# history
export HISTFILE=$HOME/.zsh_history
export HISTSIZE=10000
export SAVEHIST=10000
setopt append_history
setopt hist_ignore_dups
setopt hist_ignore_space
setopt share_history

# completion
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
autoload -Uz compinit && compinit

# python debugging
export PYTHONBREAKPOINT=ipdb.set_trace
export BAT_THEME="Catppuccin Mocha"
export FZF_DEFAULT_COMMAND="fd --type f --hidden --exclude .git"
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse"

# ls colors
[ -f ~/.local/share/lscolors.sh ] && source ~/.local/share/lscolors.sh

# tool inits (guarded)
command -v fnm      >/dev/null && eval "$(fnm env --use-on-cd)"
command -v starship >/dev/null && eval "$(starship init zsh)"
command -v rbenv    >/dev/null && eval "$(rbenv init - zsh)"
if command -v atuin >/dev/null; then
  eval "$(atuin init zsh)"
  # atuin doesn't bind ctrl-p/ctrl-n — restore for history navigation (esp. over SSH)
  bindkey '^P' atuin-up-search
  bindkey '^N' down-line-or-history
fi
command -v uv       >/dev/null && eval "$(uv generate-shell-completion zsh)"
command -v zoxide   >/dev/null && eval "$(zoxide init zsh)"

# bun
if [ -d "$HOME/.bun" ]; then
  export BUN_INSTALL="$HOME/.bun"
  export PATH="$BUN_INSTALL/bin:$PATH"
  [ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"
fi


# machine-local config (paths, tools — not tracked in version control)
[ -f ~/.local.zsh ] && source ~/.local.zsh

# secrets (API keys, tokens — not tracked in version control)
[ -f ~/.secrets.zsh ] && source ~/.secrets.zsh
