export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin

export CASSANDRA_USE_JDK11=true

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"
export BAT_THEME="ansi"

# Added by Windsurf
export PATH="$HOME/.codeium/windsurf/bin:$PATH"

export RAPIDAPI_KEY=
export NPM_TOKEN=

export DOTNET_ROOT="$HOME/.dotnet"
export PATH="$HOME/.dotnet:$PATH"
export PATH="$HOME/.antigravity/antigravity/bin:$PATH"

export NUGET_GITLAB_USR=""
export NUGET_GITLAB_TOKEN=""

export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"

export LOCALCRYPT_PASSPHRASE=""
export LOCALCRYPT_JWT_SECRET=""
export LOCALCRYPT_ENV="development"

export EDITOR=vim

export PATH="$HOME/bin:$PATH"

# Aliases
alias pwr="pwd | sed 's|$HOME|~|'"
alias rider="open -a Rider"
alias cursor="open -a Cursor"
alias lx="ls -la --color=auto"