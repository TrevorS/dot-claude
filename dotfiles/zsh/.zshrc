# path
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="$HOME/go/bin:$PATH"
export PATH="$HOME/.cache/lm-studio/bin:$PATH"
export PATH="/opt/homebrew/bin:$PATH"
export PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:$PATH"
export PATH="/opt/homebrew/opt/sqlite/bin:$PATH"
export PATH="/opt/homebrew/lib:$PATH"
export MANPATH="/usr/local/opt/coreutils/libexec/gnuman:$MANPATH"
export LIBRARY_PATH=/opt/homebrew/lib:$LIBRARY_PATH

# editor
export EDITOR="nvim"

# aliases
alias ls="ls --color=auto"
alias l="ls"
alias la="ls -la"
alias lah="ls -lah"
alias vim="nvim"
alias cat="bat"

alias gst="git status"
alias gaa="git add --all"
alias gc="git commit --verbose"
alias gd="git diff"
alias gdc="git diff --cached"
alias gb="git branch"
alias gco="git checkout"
alias gcm="git checkout master"
alias gcd="git checkout dev"

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

# tool inits (guarded)
command -v fnm      >/dev/null && eval "$(fnm env --use-on-cd)"
command -v starship >/dev/null && eval "$(starship init zsh)"
command -v rbenv    >/dev/null && eval "$(rbenv init - zsh)"
command -v atuin    >/dev/null && eval "$(atuin init zsh)"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# ollama
ollama_update_all() {
  echo "Fetching list of installed Ollama models..."
  local models=($(ollama ls | tail -n +2 | awk '{print $1}'))

  if [ ${#models[@]} -eq 0 ]; then
    echo "No models found."
    return 1
  fi

  echo "Updating ${#models[@]} model(s)..."
  for model in "${models[@]}"; do
    echo "Pulling latest version of '$model'..."
    ollama pull "$model"
    echo ""
  done

  echo "All models checked and pulled."
}

# secrets (API keys, tokens — not tracked in version control)
[ -f ~/.secrets.zsh ] && source ~/.secrets.zsh
