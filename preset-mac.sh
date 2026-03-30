# =============================================================================
# preset-mac.sh — Environment setup sourced by ~/.zshrc
# Managed by dotfiles repo. Secrets use empty placeholders.
# =============================================================================

# ── Homebrew (Apple Silicon) ─────────────────────────────────────────────────
if [ -d "/opt/homebrew" ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# ── Go ───────────────────────────────────────────────────────────────────────
export GOPATH="$HOME/go"
export PATH="$PATH:$GOPATH/bin"

# ── Java / Cassandra ────────────────────────────────────────────────────────
export CASSANDRA_USE_JDK11=true

# ── pnpm ─────────────────────────────────────────────────────────────────────
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# ── nvm ──────────────────────────────────────────────────────────────────────
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"

# ── fnm (Fast Node Manager) ─────────────────────────────────────────────────
if command -v fnm &>/dev/null; then
  eval "$(fnm env --use-on-cd)"
fi

# ── mise (runtime manager) ──────────────────────────────────────────────────
if command -v mise &>/dev/null; then
  eval "$(mise activate zsh)"
fi

# ── asdf ─────────────────────────────────────────────────────────────────────
export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"

# ── Rust / Cargo ─────────────────────────────────────────────────────────────
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# ── .NET ─────────────────────────────────────────────────────────────────────
export DOTNET_ROOT="$HOME/.dotnet"
export PATH="$HOME/.dotnet:$PATH"

# ── bat ──────────────────────────────────────────────────────────────────────
export BAT_THEME="ansi"

# ── Windsurf ─────────────────────────────────────────────────────────────────
export PATH="$HOME/.codeium/windsurf/bin:$PATH"

# ── Antigravity ──────────────────────────────────────────────────────────────
export PATH="$HOME/.antigravity/antigravity/bin:$PATH"

# ── ~/bin ────────────────────────────────────────────────────────────────────
export PATH="$HOME/bin:$PATH"

# ── Editor ───────────────────────────────────────────────────────────────────
export EDITOR=vim

# =============================================================================
# Secrets (empty placeholders — fill in via wizard or manually)
# =============================================================================

export RAPIDAPI_KEY=
export NPM_TOKEN=

export NUGET_GITLAB_USR=""
export NUGET_GITLAB_TOKEN=""

export LOCALCRYPT_PASSPHRASE=""
export LOCALCRYPT_JWT_SECRET=""
export LOCALCRYPT_ENV="development"

# =============================================================================
# Aliases
# =============================================================================

alias pwr="pwd | sed 's|$HOME|~|'"
alias rider="open -a Rider"
alias cursor="open -a Cursor"
alias lx="ls -la --color=auto"
