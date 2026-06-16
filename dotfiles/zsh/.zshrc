# ── path ────────────────────────────────────────────────────────────────────
# last prepend wins — user bins must come after system bins
# homebrew — macOS (/opt/homebrew) only; Linux already ships GNU coreutils
if [[ -d /opt/homebrew ]]; then
  export PATH="/opt/homebrew/opt/sqlite/bin:$PATH"
  # GNU coreutils without the g-prefix, so sed/ls/etc. behave like Linux
  export PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:$PATH"
  export PATH="/opt/homebrew/bin:$PATH"
  export MANPATH="/opt/homebrew/opt/coreutils/libexec/gnuman:$MANPATH"
  export LIBRARY_PATH="/opt/homebrew/lib:$LIBRARY_PATH"
elif [[ -d /home/linuxbrew/.linuxbrew ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi
if (( $+commands[brew] )); then
  export HOMEBREW_NO_AUTO_UPDATE=1
  export HOMEBREW_NO_ENV_HINTS=1
  export HOMEBREW_NO_ANALYTICS=1
  export HOMEBREW_BAT=1
  # macOS 27 preview ships /usr/bin/curl linked against LibreSSL 3.3.6, which
  # throws `bad decrypt` (curl exit 56) mid-stream on HTTP/2 cask downloads.
  # Prefer brewed curl (OpenSSL) when it's installed; the guard means brew never
  # breaks if curl is absent, and this is harmless once system curl is fixed.
  [[ -x ${${commands[brew]}:h:h}/opt/curl/bin/curl ]] && export HOMEBREW_FORCE_BREWED_CURL=1
  # Same bug bites interactive curl — front the keg-only brewed curl so plain
  # `curl` is the OpenSSL build too. (Uses OpenSSL's CA bundle, not Keychain.)
  [[ -d ${${commands[brew]}:h:h}/opt/curl/bin ]] && export PATH="${${commands[brew]}:h:h}/opt/curl/bin:$PATH"
fi
export PATH="$HOME/.cache/lm-studio/bin:$PATH"
export PATH="$HOME/go/bin:$PATH"
# CUDA toolkit (nvcc) — installed at /usr/local/cuda but not on PATH by default
if [[ -d /usr/local/cuda/bin ]]; then
  export PATH="/usr/local/cuda/bin:$PATH"
  export LD_LIBRARY_PATH="/usr/local/cuda/lib64${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
fi
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="$HOME/.luarocks/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

# ── command shims ───────────────────────────────────────────────────────────
# Resolve a command to the first installed candidate so this config stays
# portable where a tool is absent or renamed (Debian: bat→batcat, fd→fdfind;
# macOS: BSD sed, GNU sed as gsed). Aliases the name to the winner when it
# differs and records it in $BIN for the env vars below. No-op when none of the
# candidates exist, so nothing ever resolves to a missing binary.
typeset -gA BIN
shim() {
  local name=$1 cand
  for cand in "${@:2}"; do
    (( $+commands[$cand] )) || continue
    BIN[$name]=$cand
    [[ $cand != $name ]] && alias $name="$cand"
    return 0
  done
}

shim cat bat        # macOS/cargo install; plain cat on a bare box
shim sed gsed sed   # macOS: GNU sed as gsed; Linux sed is already GNU
shim fd  fd fdfind  # Debian/Ubuntu package fd as fdfind

# ── aliases ─────────────────────────────────────────────────────────────────
# GNU ls uses --color=auto; BSD ls (macOS sans coreutils) uses -G
if ls --color=auto -d . >/dev/null 2>&1; then
  alias ls="ls --color=auto"
else
  alias ls="ls -G"
fi
alias l="ls"
alias la="ls -la"
alias lah="ls -lah"
alias vim="nvim"
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
alias yolo="claude --dangerously-skip-permissions"

alias dcu="docker compose up"
alias dcd="docker compose down"

# ── environment ─────────────────────────────────────────────────────────────
export EDITOR="nvim"
export PYTHONBREAKPOINT=ipdb.set_trace
export BAT_THEME="Catppuccin Mocha"
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse"
[[ -n $BIN[fd] ]] && export FZF_DEFAULT_COMMAND="$BIN[fd] --type f --hidden --exclude .git"
[[ -f ~/.config/ripgrep/config ]] && export RIPGREP_CONFIG_PATH="$HOME/.config/ripgrep/config"
[[ -f ~/.local/share/lscolors.sh ]] && source ~/.local/share/lscolors.sh

# ── shell options ───────────────────────────────────────────────────────────
export HISTFILE=$HOME/.zsh_history
export HISTSIZE=10000
export SAVEHIST=10000
setopt append_history
setopt hist_ignore_dups
setopt hist_ignore_space
setopt share_history

zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
autoload -Uz compinit && compinit

# ── keybindings ─────────────────────────────────────────────────────────────
# History navigation (esp. over SSH where vi-insert default eats them). Bound
# unconditionally so they work without atuin; the atuin init below overrides ^R + ^P.
bindkey '^P' up-line-or-history
bindkey '^N' down-line-or-history
bindkey '^R' history-incremental-search-backward

# ── tool inits (guarded) ────────────────────────────────────────────────────
command -v fnm      >/dev/null && eval "$(fnm env --use-on-cd)"
command -v starship >/dev/null && eval "$(starship init zsh)"
command -v rbenv    >/dev/null && eval "$(rbenv init - zsh)"
command -v uv       >/dev/null && eval "$(uv generate-shell-completion zsh)"
command -v zoxide   >/dev/null && eval "$(zoxide init zsh)"
if command -v atuin >/dev/null; then
  eval "$(atuin init zsh)"
  bindkey '^P' atuin-up-search
fi

if [[ -d "$HOME/.bun" ]]; then
  export BUN_INSTALL="$HOME/.bun"
  export PATH="$BUN_INSTALL/bin:$PATH"
  [[ -s "$HOME/.bun/_bun" ]] && source "$HOME/.bun/_bun"
fi

# ── machine-local (untracked) ───────────────────────────────────────────────
[[ -f ~/.local.zsh ]]   && source ~/.local.zsh    # paths, tools
[[ -f ~/.secrets.zsh ]] && source ~/.secrets.zsh  # API keys, tokens
