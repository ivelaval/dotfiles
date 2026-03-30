#!/usr/bin/env bash
# mac-setup.sh — Robust macOS bootstrap script with dry-run support
# Usage: bash mac-setup.sh [--dry-run] [--section <name>] [--log-file <path>] [--help]

set -uo pipefail

# =============================================================================
# Constants
# =============================================================================

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# =============================================================================
# Global State
# =============================================================================

DRY_RUN=false
SECTION=""
LOG_FILE="$HOME/.mac-setup.log"
ERRORS=()

# =============================================================================
# Utility Functions
# =============================================================================

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"
}

info() {
  echo -e "${GREEN}[OK]${NC} $*"
  log "[OK] $*"
}

warn() {
  echo -e "${YELLOW}[SKIP]${NC} $*"
  log "[SKIP] $*"
}

err() {
  echo -e "${RED}[ERROR]${NC} $*"
  log "[ERROR] $*"
  ERRORS+=("$*")
}

section_header() {
  echo ""
  echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}  $*${NC}"
  echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  log "=== $* ==="
}

run_cmd() {
  if $DRY_RUN; then
    echo -e "  ${BLUE}[DRY-RUN]${NC} $*"
    log "[DRY-RUN] $*"
    return 0
  fi
  log "[RUN] $*"
  if eval "$@" >> "$LOG_FILE" 2>&1; then
    return 0
  else
    err "Command failed: $*"
    return 1
  fi
}

brew_install_formula() {
  local pkg="$1"
  if brew list --formula 2>/dev/null | grep -q "^${pkg}$"; then
    warn "$pkg already installed"
  else
    echo -e "  Installing formula: ${BOLD}$pkg${NC}"
    run_cmd "brew install '$pkg'"
    if [ $? -eq 0 ] && ! $DRY_RUN; then
      info "$pkg installed"
    fi
  fi
}

brew_install_cask() {
  local pkg="$1"
  # Check if installed via brew
  if brew list --cask 2>/dev/null | grep -q "^${pkg}$"; then
    warn "$pkg already installed (brew)"
    return 0
  fi
  # Check if app already exists in /Applications (installed outside brew)
  # Try to get the real app name from brew info artifacts
  local app_name
  app_name=$(brew info --cask "$pkg" 2>/dev/null | grep -A1 "^==> Artifacts" | tail -1 | sed 's/ (App)//;s/^ *//')
  if [ -n "$app_name" ] && { [ -d "/Applications/${app_name}" ] || [ -d "$HOME/Applications/${app_name}" ]; }; then
    warn "$pkg already installed (${app_name} found in /Applications)"
    return 0
  fi
  # Fallback: search /Applications with a case-insensitive match on the cask name
  local search_name
  search_name=$(echo "$pkg" | sed 's/-/ /g')
  if find /Applications -maxdepth 1 -iname "*${search_name}*" -print -quit 2>/dev/null | grep -q .; then
    local found_app
    found_app=$(find /Applications -maxdepth 1 -iname "*${search_name}*" -print -quit 2>/dev/null)
    warn "$pkg already installed ($(basename "$found_app") found in /Applications)"
    return 0
  fi
  echo -e "  Installing cask: ${BOLD}$pkg${NC}"
  run_cmd "brew install --cask '$pkg'"
  if [ $? -eq 0 ] && ! $DRY_RUN; then
    info "$pkg installed"
  fi
}

create_symlink() {
  local source="$1"
  local target="$2"

  if [ ! -e "$source" ]; then
    err "Symlink source does not exist: $source"
    return 1
  fi

  if [ -L "$target" ] && [ "$(readlink "$target")" = "$source" ]; then
    warn "Symlink already correct: $target -> $source"
    return 0
  fi

  # Backup existing file/dir if it exists and is not a symlink
  if [ -e "$target" ] || [ -L "$target" ]; then
    local backup="${target}.backup.$(date +%s)"
    echo -e "  ${YELLOW}Backing up${NC} $target -> $backup"
    run_cmd "mv '$target' '$backup'"
  fi

  # Ensure parent directory exists
  local parent_dir
  parent_dir="$(dirname "$target")"
  if [ ! -d "$parent_dir" ]; then
    run_cmd "mkdir -p '$parent_dir'"
  fi

  run_cmd "ln -s '$source' '$target'"
  if [ $? -eq 0 ]; then
    info "Symlinked: $target -> $source"
  fi
}

# =============================================================================
# Argument Parsing
# =============================================================================

show_help() {
  cat << 'EOF'
mac-setup.sh — Robust macOS bootstrap script

Usage:
  bash mac-setup.sh [OPTIONS]

Options:
  --dry-run            Print what would be done without executing
  --section <name>     Run only a specific section
  --log-file <path>    Log file path (default: ~/.mac-setup.log)
  --help               Show this help message

Available sections:
  xcode        Xcode Command Line Tools
  homebrew     Homebrew installation and update
  taps         Homebrew tap repositories
  formulae     CLI tools and packages (brew formulae)
  casks        GUI applications (brew casks)
  mas          Mac App Store apps
  shell        Oh My Zsh, Powerlevel10k, plugins
  symlinks     Dotfile config symlinks
  runtimes     Runtime managers (nvm, rustup, dotnet)
  tpm          Tmux Plugin Manager
  directories  Directory structure
  macos        macOS system defaults
  wizard       Post-setup interactive wizard (secrets, auth, plugins)

Examples:
  bash mac-setup.sh --dry-run              # See everything that would happen
  bash mac-setup.sh --section formulae     # Install only CLI tools
  bash mac-setup.sh --dry-run --section casks  # Preview GUI app installs
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --section)
      SECTION="$2"
      shift 2
      ;;
    --log-file)
      LOG_FILE="$2"
      shift 2
      ;;
    --help)
      show_help
      exit 0
      ;;
    *)
      echo -e "${RED}Unknown option: $1${NC}"
      show_help
      exit 1
      ;;
  esac
done

# =============================================================================
# Section: Xcode Command Line Tools
# =============================================================================

setup_xcode() {
  section_header "Xcode Command Line Tools"

  if xcode-select -p &>/dev/null; then
    warn "Xcode Command Line Tools already installed"
  else
    echo "  Installing Xcode Command Line Tools..."
    run_cmd "xcode-select --install"
    if ! $DRY_RUN; then
      echo -e "  ${YELLOW}Waiting for Xcode CLI tools installation to complete...${NC}"
      echo -e "  ${YELLOW}Please complete the installation dialog, then press Enter.${NC}"
      read -r
    fi
  fi
}

# =============================================================================
# Section: Homebrew
# =============================================================================

setup_homebrew() {
  section_header "Homebrew"

  if command -v brew &>/dev/null; then
    warn "Homebrew already installed"
  else
    echo "  Installing Homebrew..."
    run_cmd '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
  fi

  # Apple Silicon PATH setup
  if [ "$(uname -m)" = "arm64" ] && [ -f /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    info "Apple Silicon Homebrew path configured"
  fi

  echo "  Updating Homebrew..."
  run_cmd "brew update"
}

# =============================================================================
# Section: Brew Taps
# =============================================================================

install_brew_taps() {
  section_header "Homebrew Taps"

  local TAPS=(
    adoptopenjdk/openjdk
    anomalyco/tap
    auth0/auth0-cli
    b-ramsey/kali
    caarlos0/tap
    heroku/brew
    ngrok/ngrok
    oven-sh/bun
    supabase/tap
  )

  for tap in "${TAPS[@]}"; do
    if brew tap 2>/dev/null | grep -q "^${tap}$"; then
      warn "Tap $tap already added"
    else
      echo -e "  Adding tap: ${BOLD}$tap${NC}"
      run_cmd "brew tap '$tap'"
      if [ $? -eq 0 ] && ! $DRY_RUN; then
        info "Tap $tap added"
      fi
    fi
  done
}

# =============================================================================
# Section: Brew Formulae
# =============================================================================

install_brew_formulae() {
  section_header "Homebrew Formulae (CLI tools)"

  local FORMULAE=(
    # Core
    git
    tmux
    vim
    node
    ripgrep

    # Shell & terminal
    fish
    bat
    fzf
    htop
    gtop
    ctop
    neofetch
    neovim
    ranger
    tree
    tig
    wget

    # Development tools
    gh
    gitleaks
    biome
    graphviz
    maven
    protobuf
    grpcui
    grpcurl
    watchman
    http-server

    # Languages & runtimes
    go
    openjdk@11
    "python@3.9"
    "python@3.10"
    coreutils

    # Package/version managers
    asdf
    fnm
    mise
    pnpm
    yarn

    # Databases
    "postgresql@15"
    redis
    cassandra
    golang-migrate

    # Media
    ffmpeg
    yt-dlp

    # Containers
    docker-compose

    # CLI utilities
    auth0
    calcurse
    fx
    gemini-cli
    mtr
    supabase
    terminal-notifier
    timer
    tmuxinator
  )

  for pkg in "${FORMULAE[@]}"; do
    brew_install_formula "$pkg"
  done
}

# =============================================================================
# Section: Brew Casks
# =============================================================================

install_brew_casks() {
  section_header "Homebrew Casks (GUI applications)"

  local CASKS=(
    # Browsers
    firefox
    google-chrome
    brave-browser
    tor-browser
    microsoft-edge
    zen-browser

    # Editors & IDEs
    visual-studio-code
    cursor
    windsurf
    zed
    kiro
    android-studio
    jetbrains-toolbox  # Rider, GoLand, IntelliJ, WebStorm, DataGrip managed via Toolbox
    # fleet — discontinued by JetBrains (Dec 2025)

    # Terminals
    iterm2
    warp

    # Communication
    slack
    discord
    whatsapp
    zoom

    # Design & Prototyping
    figma
    framer
    balsamiq-wireframes
    drawio
    miro

    # Dev tools
    docker
    postman
    hoppscotch
    altair-graphql-client
    sourcetree
    github         # GitHub Desktop
    dbeaver-community
    beekeeper-studio
    tableplus
    pgadmin4
    mongodb-compass
    mysqlworkbench
    ngrok
    dash
    responsively
    burp-suite

    # Media
    vlc
    spotify
    obs

    # Productivity
    notion
    notion-calendar
    typora
    google-drive
    adobe-acrobat-reader
    antigravity

    # Utilities
    bitwarden
    bartender
    aldente
    keka
    utm
    balenaetcher
    codex
    comet
    twitch-studio
    arduino-ide

    # AI
    chatgpt
    claude

    # Fonts
    font-fira-code
    font-meslo-lg-nerd-font
    font-fira-code-nerd-font

    # Java runtimes
    temurin@8     # successor to adoptopenjdk8
    zulu@11
  )

  for pkg in "${CASKS[@]}"; do
    brew_install_cask "$pkg"
  done
}

# =============================================================================
# Section: Mac App Store
# =============================================================================

install_mas_apps() {
  section_header "Mac App Store Apps"

  if ! command -v mas &>/dev/null; then
    echo "  Installing mas (Mac App Store CLI)..."
    run_cmd "brew install mas"
  fi

  if $DRY_RUN; then
    echo -e "  ${BLUE}[DRY-RUN]${NC} Would install App Store apps (requires sign-in)"
    return 0
  fi

  if ! mas account &>/dev/null; then
    warn "Not signed in to the Mac App Store. Please sign in manually first."
    warn "Skipping App Store installs."
    return 0
  fi

  local MAS_APPS=(
    "497799835:Xcode"
    "441258766:Magnet"
    "6714467650:Perplexity"
    "1153157709:Speedtest"
    "1351639930:Gifski"
    "1268457877:Good Timer"
    "1438389787:Pasta"
    "1526042938:Tomito"
    "6445813049:Spark Desktop"
    "1352778147:Bitwarden"
    "1355679052:Dropover"
    "470158793:Keka"
    "408981434:iMovie"
    "682658836:GarageBand"
    "1456120961:Swift Playground"
  )

  for entry in "${MAS_APPS[@]}"; do
    local id="${entry%%:*}"
    local name="${entry##*:}"
    if mas list 2>/dev/null | grep -q "^${id} "; then
      warn "$name already installed (App Store)"
    else
      echo -e "  Installing: ${BOLD}$name${NC} ($id)"
      run_cmd "mas install '$id'"
      if [ $? -eq 0 ]; then
        info "$name installed from App Store"
      fi
    fi
  done
}

# =============================================================================
# Section: Shell Setup
# =============================================================================

setup_shell() {
  section_header "Shell Setup (Oh My Zsh + Powerlevel10k + Plugins)"

  local ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

  # Oh My Zsh
  if [ -d "$HOME/.oh-my-zsh" ]; then
    warn "Oh My Zsh already installed"
  else
    echo "  Installing Oh My Zsh..."
    run_cmd 'RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'
    if [ $? -eq 0 ]; then
      info "Oh My Zsh installed"
    fi
  fi

  # Powerlevel10k theme
  if [ -d "$ZSH_CUSTOM/themes/powerlevel10k" ]; then
    warn "Powerlevel10k already installed"
  else
    echo "  Installing Powerlevel10k theme..."
    run_cmd "git clone --depth=1 https://github.com/romkatv/powerlevel10k.git '$ZSH_CUSTOM/themes/powerlevel10k'"
    if [ $? -eq 0 ]; then
      info "Powerlevel10k installed"
    fi
  fi

  # zsh-autosuggestions
  if [ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    warn "zsh-autosuggestions already installed"
  else
    echo "  Installing zsh-autosuggestions..."
    run_cmd "git clone https://github.com/zsh-users/zsh-autosuggestions '$ZSH_CUSTOM/plugins/zsh-autosuggestions'"
    if [ $? -eq 0 ]; then
      info "zsh-autosuggestions installed"
    fi
  fi

  # zsh-syntax-highlighting
  if [ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    warn "zsh-syntax-highlighting already installed"
  else
    echo "  Installing zsh-syntax-highlighting..."
    run_cmd "git clone https://github.com/zsh-users/zsh-syntax-highlighting '$ZSH_CUSTOM/plugins/zsh-syntax-highlighting'"
    if [ $? -eq 0 ]; then
      info "zsh-syntax-highlighting installed"
    fi
  fi

  info "web-search plugin is bundled with Oh My Zsh (no extra install needed)"
}

# =============================================================================
# Section: Symlinks
# =============================================================================

setup_symlinks() {
  section_header "Dotfile Symlinks"

  create_symlink "$DOTFILES_DIR/tmux.conf"            "$HOME/.tmux.conf"
  create_symlink "$DOTFILES_DIR/.gitconfig"            "$HOME/.gitconfig"
  create_symlink "$DOTFILES_DIR/nvim"                  "$HOME/.config/nvim"
  create_symlink "$DOTFILES_DIR/preset-mac.sh"         "$HOME/preset-mac.sh"
  create_symlink "$DOTFILES_DIR/warp/themes"           "$HOME/.warp/themes"
  create_symlink "$DOTFILES_DIR/scripts/pomodoro.sh"   "$HOME/pomodoro.sh"

  echo ""
  echo -e "  ${YELLOW}Reminder:${NC} Ensure your ~/.zshrc sources the following:"
  echo "    source ~/preset-mac.sh"
  echo "    source ~/pomodoro.sh"
  echo ""
  echo -e "  ${YELLOW}Reminder:${NC} Populate secrets in ~/preset-mac.sh (they are empty by default)"
}

# =============================================================================
# Section: Runtime Managers
# =============================================================================

setup_runtime_managers() {
  section_header "Runtime Managers"

  # nvm
  if [ -d "$HOME/.nvm" ]; then
    warn "nvm already installed"
  else
    echo "  Installing nvm..."
    run_cmd 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash'
    if [ $? -eq 0 ]; then
      info "nvm installed"
    fi
  fi

  # Rust / Cargo
  if command -v rustup &>/dev/null; then
    warn "Rust (rustup) already installed"
  else
    echo "  Installing Rust via rustup..."
    run_cmd "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y"
    if [ $? -eq 0 ]; then
      info "Rust installed"
    fi
  fi

  # .NET SDK
  if command -v dotnet &>/dev/null; then
    warn ".NET SDK already installed"
  else
    echo "  Installing .NET SDK..."
    run_cmd 'curl -sSL https://dot.net/v1/dotnet-install.sh | bash /dev/stdin --channel LTS'
    if [ $? -eq 0 ]; then
      info ".NET SDK installed"
    fi
  fi

  info "mise, asdf, fnm are installed via Homebrew formulae"
}

# =============================================================================
# Section: TPM (Tmux Plugin Manager)
# =============================================================================

setup_tpm() {
  section_header "Tmux Plugin Manager (TPM)"

  if [ -d "$HOME/.tmux/plugins/tpm" ]; then
    warn "TPM already installed"
  else
    echo "  Installing TPM..."
    run_cmd "git clone https://github.com/tmux-plugins/tpm '$HOME/.tmux/plugins/tpm'"
    if [ $? -eq 0 ]; then
      info "TPM installed"
    fi
  fi

  echo -e "  ${YELLOW}Note:${NC} Press ${BOLD}prefix + I${NC} inside tmux to install plugins"
}

# =============================================================================
# Section: Directories
# =============================================================================

setup_directories() {
  section_header "Directory Structure"

  local DIRS=(
    "$HOME/github"
    "$HOME/vennet"
    "$HOME/bin"
    "$HOME/.config"
    "$HOME/.warp"
  )

  for dir in "${DIRS[@]}"; do
    if [ -d "$dir" ]; then
      warn "Directory already exists: $dir"
    else
      run_cmd "mkdir -p '$dir'"
      if [ $? -eq 0 ]; then
        info "Created directory: $dir"
      fi
    fi
  done
}

# =============================================================================
# Section: macOS Defaults
# =============================================================================

setup_macos_defaults() {
  section_header "macOS System Defaults"

  echo "  Configuring keyboard..."
  run_cmd "defaults write NSGlobalDomain KeyRepeat -int 2"
  run_cmd "defaults write NSGlobalDomain InitialKeyRepeat -int 15"
  run_cmd "defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false"

  echo "  Configuring Finder..."
  run_cmd "defaults write NSGlobalDomain AppleShowAllExtensions -bool true"
  run_cmd "defaults write com.apple.finder AppleShowAllFiles -bool true"
  run_cmd "defaults write com.apple.finder ShowPathbar -bool true"
  run_cmd "defaults write com.apple.finder ShowStatusBar -bool true"
  run_cmd "defaults write com.apple.finder _FXShowPosixPathInTitle -bool true"
  run_cmd 'defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"'

  echo "  Configuring Dock..."
  run_cmd "defaults write com.apple.dock autohide -bool true"
  run_cmd "defaults write com.apple.dock autohide-delay -float 0"
  run_cmd "defaults write com.apple.dock tilesize -int 48"
  run_cmd "defaults write com.apple.dock show-recents -bool false"

  echo "  Configuring screenshots..."
  run_cmd "mkdir -p '$HOME/Desktop/Screenshots'"
  run_cmd 'defaults write com.apple.screencapture location -string "$HOME/Desktop/Screenshots"'
  run_cmd 'defaults write com.apple.screencapture type -string "png"'

  echo "  Configuring Safari developer menu..."
  # Safari defaults may fail if Safari hasn't been opened or due to SIP — non-critical
  if defaults read com.apple.Safari &>/dev/null; then
    run_cmd "defaults write com.apple.Safari IncludeDevelopMenu -bool true"
    run_cmd "defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true"
  else
    warn "Safari preferences not accessible (open Safari at least once, or check SIP permissions)"
  fi

  echo "  Configuring Trackpad..."
  run_cmd "defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true"

  if ! $DRY_RUN; then
    info "Some defaults require logout or restart to take effect"
  fi
}

# =============================================================================
# Section: Post-Setup Wizard
# =============================================================================

ask_value() {
  local prompt="$1"
  local default="$2"
  local value
  if [ -n "$default" ]; then
    echo -ne "  ${prompt} [${default}]: " >&2
  else
    echo -ne "  ${prompt}: " >&2
  fi
  read -r value
  echo "${value:-$default}"
}

ask_yes_no() {
  local prompt="$1"
  local default="${2:-y}"
  local value
  if [ "$default" = "y" ]; then
    echo -ne "  ${prompt} [Y/n]: "
  else
    echo -ne "  ${prompt} [y/N]: "
  fi
  read -r value
  value="${value:-$default}"
  [[ "$value" =~ ^[Yy] ]]
}

setup_wizard() {
  section_header "Post-Setup Wizard"

  if $DRY_RUN; then
    echo -e "  ${BLUE}[DRY-RUN]${NC} Would launch interactive wizard to configure:"
    echo "    - Secrets in preset-mac.sh"
    echo "    - Source lines in ~/.zshrc"
    echo "    - SSH key generation + upload to GitHub"
    echo "    - GitHub CLI, Docker, AWS authentication"
    echo "    - npmrc private registry tokens"
    echo "    - Tmux plugins (TPM)"
    echo "    - Neovim plugins (PackerSync)"
    echo "    - Powerlevel10k theme configuration"
    return 0
  fi

  echo -e "  This wizard will help you configure secrets, auth, and plugins."
  echo -e "  Press Enter to skip any step or leave a value empty.\n"

  # ── 1. Secrets in preset-mac.sh ──────────────────────────────────────────
  local preset_file="$HOME/preset-mac.sh"
  if [ -L "$preset_file" ]; then
    preset_file="$(readlink "$preset_file")"
  fi

  if [ ! -f "$preset_file" ]; then
    warn "preset-mac.sh not found. Run --section symlinks first. Skipping secrets."
  else
    # Check if secrets are already populated (non-empty values)
    local secrets_empty=false
    if grep -q 'RAPIDAPI_KEY=$' "$preset_file" 2>/dev/null || \
       grep -q 'NPM_TOKEN=$' "$preset_file" 2>/dev/null || \
       grep -q 'NUGET_GITLAB_USR=""' "$preset_file" 2>/dev/null; then
      secrets_empty=true
    fi

    if $secrets_empty; then
      if ask_yes_no "Configure secrets in preset-mac.sh? (some are empty)"; then
        echo ""
        echo -e "  ${BOLD}Environment Secrets${NC}"
        echo -e "  (leave empty to keep the current placeholder)\n"

        local rapidapi npm_token nuget_usr nuget_token localcrypt_pass localcrypt_jwt localcrypt_env

        rapidapi=$(ask_value "RAPIDAPI_KEY" "")
        npm_token=$(ask_value "NPM_TOKEN" "")
        nuget_usr=$(ask_value "NUGET_GITLAB_USR" "")
        nuget_token=$(ask_value "NUGET_GITLAB_TOKEN" "")
        localcrypt_pass=$(ask_value "LOCALCRYPT_PASSPHRASE" "")
        localcrypt_jwt=$(ask_value "LOCALCRYPT_JWT_SECRET" "")
        localcrypt_env=$(ask_value "LOCALCRYPT_ENV" "development")

        [ -n "$rapidapi" ] && sed -i '' "s|^export RAPIDAPI_KEY=.*|export RAPIDAPI_KEY=$rapidapi|" "$preset_file"
        [ -n "$npm_token" ] && sed -i '' "s|^export NPM_TOKEN=.*|export NPM_TOKEN=$npm_token|" "$preset_file"
        [ -n "$nuget_usr" ] && sed -i '' "s|^export NUGET_GITLAB_USR=.*|export NUGET_GITLAB_USR=\"$nuget_usr\"|" "$preset_file"
        [ -n "$nuget_token" ] && sed -i '' "s|^export NUGET_GITLAB_TOKEN=.*|export NUGET_GITLAB_TOKEN=\"$nuget_token\"|" "$preset_file"
        [ -n "$localcrypt_pass" ] && sed -i '' "s|^export LOCALCRYPT_PASSPHRASE=.*|export LOCALCRYPT_PASSPHRASE=\"$localcrypt_pass\"|" "$preset_file"
        [ -n "$localcrypt_jwt" ] && sed -i '' "s|^export LOCALCRYPT_JWT_SECRET=.*|export LOCALCRYPT_JWT_SECRET=\"$localcrypt_jwt\"|" "$preset_file"
        [ -n "$localcrypt_env" ] && sed -i '' "s|^export LOCALCRYPT_ENV=.*|export LOCALCRYPT_ENV=\"$localcrypt_env\"|" "$preset_file"

        info "Secrets updated in preset-mac.sh"
      fi
    else
      warn "Secrets in preset-mac.sh already populated"
    fi
  fi

  echo ""

  # ── 2. Configure ~/.zshrc source lines ───────────────────────────────────
  local zshrc="$HOME/.zshrc"
  local zshrc_needs_preset=true
  local zshrc_needs_pomodoro=true

  if [ -f "$zshrc" ]; then
    grep -q "source ~/preset-mac.sh" "$zshrc" 2>/dev/null && zshrc_needs_preset=false
    grep -q "source ~/pomodoro.sh" "$zshrc" 2>/dev/null && zshrc_needs_pomodoro=false
  fi

  if $zshrc_needs_preset || $zshrc_needs_pomodoro; then
    if ask_yes_no "Add missing source lines to ~/.zshrc?"; then
      if [ ! -f "$zshrc" ]; then
        touch "$zshrc"
        info "Created ~/.zshrc"
      fi

      if $zshrc_needs_preset; then
        echo "" >> "$zshrc"
        echo "# Dotfiles environment setup" >> "$zshrc"
        echo "source ~/preset-mac.sh" >> "$zshrc"
        info "Added 'source ~/preset-mac.sh' to ~/.zshrc"
      fi

      if $zshrc_needs_pomodoro; then
        echo "source ~/pomodoro.sh" >> "$zshrc"
        info "Added 'source ~/pomodoro.sh' to ~/.zshrc"
      fi
    fi
  else
    warn "~/.zshrc already has source lines for preset-mac.sh and pomodoro.sh"
  fi

  echo ""

  # ── 3. SSH Keys ──────────────────────────────────────────────────────────
  if [ -f "$HOME/.ssh/id_ed25519" ] || [ -f "$HOME/.ssh/id_rsa" ]; then
    warn "SSH key already exists (~/.ssh/id_ed25519 or ~/.ssh/id_rsa)"
  elif ask_yes_no "Generate SSH key?"; then
    local ssh_email ssh_type
    ssh_email=$(ask_value "Email for SSH key" "ivelaval@gmail.com")
    ssh_type=$(ask_value "Key type (ed25519/rsa)" "ed25519")

    local ssh_file="$HOME/.ssh/id_${ssh_type}"
    if [ -f "$ssh_file" ]; then
      warn "SSH key already exists at $ssh_file"
    else
      mkdir -p "$HOME/.ssh"
      ssh-keygen -t "$ssh_type" -C "$ssh_email" -f "$ssh_file"
      eval "$(ssh-agent -s)" >> "$LOG_FILE" 2>&1
      ssh-add "$ssh_file" >> "$LOG_FILE" 2>&1
      info "SSH key generated at $ssh_file"
      echo ""
      echo -e "  ${BOLD}Your public key:${NC}"
      echo ""
      cat "${ssh_file}.pub"
      echo ""
      if command -v pbcopy &>/dev/null; then
        cat "${ssh_file}.pub" | pbcopy
        info "Public key copied to clipboard"
      fi
    fi

    # Upload to GitHub via gh CLI
    if [ -f "${ssh_file}.pub" ] && command -v gh &>/dev/null; then
      if ask_yes_no "Upload this SSH key to your GitHub account?"; then
        local key_title
        key_title=$(ask_value "Key title for GitHub" "$(hostname)-$(date +%Y%m%d)")

        # Ensure gh is authenticated first
        if ! gh auth status &>/dev/null; then
          echo -e "  ${YELLOW}GitHub CLI not authenticated yet. Logging in...${NC}"
          gh auth login
        fi

        if gh auth status &>/dev/null; then
          gh ssh-key add "${ssh_file}.pub" --title "$key_title" --type authentication
          if [ $? -eq 0 ]; then
            info "SSH key uploaded to GitHub as '$key_title'"
          else
            err "Failed to upload SSH key to GitHub"
          fi
        else
          err "GitHub CLI authentication failed, cannot upload SSH key"
        fi
      fi
    fi
  fi

  echo ""

  # ── 4. GitHub CLI auth ───────────────────────────────────────────────────
  if command -v gh &>/dev/null; then
    if gh auth status &>/dev/null; then
      warn "GitHub CLI already authenticated"
    else
      if ask_yes_no "Authenticate GitHub CLI (gh auth login)?"; then
        gh auth login
        if [ $? -eq 0 ]; then
          info "GitHub CLI authenticated"
        fi
      fi
    fi
  fi

  echo ""

  # ── 5. Docker login ─────────────────────────────────────────────────────
  if command -v docker &>/dev/null; then
    if [ -f "$HOME/.docker/config.json" ] && grep -q '"credsStore"' "$HOME/.docker/config.json" 2>/dev/null; then
      warn "Docker already configured (credsStore found)"
    else
      if ask_yes_no "Login to Docker Hub?" "n"; then
        docker login
        if [ $? -eq 0 ]; then
          info "Docker authenticated"
        fi
      fi
    fi
  fi

  echo ""

  # ── 6. AWS CLI ───────────────────────────────────────────────────────────
  if command -v aws &>/dev/null; then
    if [ -f "$HOME/.aws/credentials" ]; then
      warn "AWS credentials already configured"
    else
      if ask_yes_no "Configure AWS CLI (aws configure)?" "n"; then
        aws configure
        info "AWS CLI configured"
      fi
    fi
  fi

  echo ""

  # ── 7. npmrc private registries ──────────────────────────────────────────
  if [ -f "$HOME/.npmrc" ] && grep -q "_authToken=" "$HOME/.npmrc" 2>/dev/null; then
    warn "~/.npmrc already has auth tokens configured"
  elif ask_yes_no "Configure ~/.npmrc (private registry tokens)?" "n"; then
    local npmrc="$HOME/.npmrc"
    if [ ! -f "$npmrc" ]; then
      touch "$npmrc"
    fi

    echo ""
    echo -e "  ${BOLD}npm Registry Tokens${NC}"
    echo -e "  (leave empty to skip each one)\n"

    local npm_auth_token
    npm_auth_token=$(ask_value "npmjs.org auth token" "")
    if [ -n "$npm_auth_token" ]; then
      if grep -q "//registry.npmjs.org/" "$npmrc" 2>/dev/null; then
        sed -i '' "s|//registry.npmjs.org/:_authToken=.*|//registry.npmjs.org/:_authToken=$npm_auth_token|" "$npmrc"
      else
        echo "//registry.npmjs.org/:_authToken=$npm_auth_token" >> "$npmrc"
      fi
      info "npmjs.org token saved"
    fi

    if ask_yes_no "Add a GitLab npm registry?" "n"; then
      local gl_scope gl_project_id gl_token
      gl_scope=$(ask_value "Scope (e.g. @myorg)" "")
      gl_project_id=$(ask_value "GitLab project ID" "")
      gl_token=$(ask_value "GitLab token (glpat-...)" "")
      if [ -n "$gl_scope" ] && [ -n "$gl_project_id" ] && [ -n "$gl_token" ]; then
        echo "${gl_scope}:registry=https://gitlab.com/api/v4/projects/${gl_project_id}/packages/npm/" >> "$npmrc"
        echo "//gitlab.com/api/v4/projects/${gl_project_id}/packages/npm/:_authToken=${gl_token}" >> "$npmrc"
        info "GitLab registry for $gl_scope added"
      fi
    fi
  fi

  echo ""

  # ── 8. Tmux plugins install ─────────────────────────────────────────────
  if [ -x "$HOME/.tmux/plugins/tpm/scripts/install_plugins.sh" ]; then
    local tpm_plugin_count
    tpm_plugin_count=$(find "$HOME/.tmux/plugins" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
    if [ "$tpm_plugin_count" -gt 1 ]; then
      warn "Tmux plugins already installed ($tpm_plugin_count plugins found)"
    else
      if ask_yes_no "Install tmux plugins via TPM now?"; then
        "$HOME/.tmux/plugins/tpm/scripts/install_plugins.sh" >> "$LOG_FILE" 2>&1
        info "Tmux plugins installed"
      fi
    fi
  fi

  echo ""

  # ── 9. Neovim PackerSync ─────────────────────────────────────────────────
  if command -v nvim &>/dev/null; then
    local packer_dir="$HOME/.local/share/nvim/site/pack/packer"
    if [ -d "$packer_dir" ] && [ "$(find "$packer_dir" -maxdepth 2 -mindepth 2 -type d 2>/dev/null | wc -l | tr -d ' ')" -gt 1 ]; then
      warn "Neovim plugins already installed (packer packages found)"
    else
      if ask_yes_no "Install Neovim plugins (PackerSync)?"; then
        echo "  Running PackerSync (this may take a moment)..."
        nvim --headless -c 'autocmd User PackerComplete quitall' -c 'PackerSync' 2>> "$LOG_FILE"
        info "Neovim plugins installed"
      fi
    fi
  fi

  echo ""

  # ── 10. Powerlevel10k configure ──────────────────────────────────────────
  if [ -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ]; then
    if [ -f "$HOME/.p10k.zsh" ]; then
      warn "Powerlevel10k already configured (~/.p10k.zsh exists)"
    else
      if ask_yes_no "Run Powerlevel10k configuration wizard?"; then
        echo -e "  ${YELLOW}Launching p10k configure in a new zsh session...${NC}"
        zsh -i -c "p10k configure"
      fi
    fi
  fi

  echo ""

  # ── 11. Reminder for manual steps ────────────────────────────────────────
  section_header "Remaining Manual Steps"
  echo -e "  ${YELLOW}1.${NC} Open ${BOLD}JetBrains Toolbox${NC} and install: Rider, GoLand, IntelliJ, WebStorm, DataGrip"
  echo -e "  ${YELLOW}2.${NC} Sign in to ${BOLD}Mac App Store${NC} if not done (needed for mas installs)"
  echo -e "  ${YELLOW}3.${NC} Download manually: ${BOLD}CocCoc, Dia, Genspark, Ophiuchi, Tapo${NC}"
  echo -e "  ${YELLOW}4.${NC} ${BOLD}Logout/restart${NC} to apply macOS defaults (Dock, Finder, trackpad)"
  echo ""
}

# =============================================================================
# Summary
# =============================================================================

summary() {
  section_header "Setup Summary"

  if $DRY_RUN; then
    echo -e "  ${BLUE}This was a dry run. No changes were made.${NC}"
    echo ""
  fi

  if [ ${#ERRORS[@]} -eq 0 ]; then
    info "Setup completed successfully with no errors!"
  else
    echo -e "  ${RED}Setup completed with ${#ERRORS[@]} error(s):${NC}"
    for e in "${ERRORS[@]}"; do
      echo -e "    ${RED}- ${e}${NC}"
    done
  fi

  echo ""
  echo -e "  Log file: ${BOLD}$LOG_FILE${NC}"
}

# =============================================================================
# Main
# =============================================================================

main() {
  echo ""
  echo -e "${BOLD}  macOS Setup Script${NC}"
  echo -e "  Dotfiles: $DOTFILES_DIR"
  if $DRY_RUN; then
    echo -e "  Mode: ${BLUE}DRY RUN${NC}"
  fi
  echo ""

  log "========================================="
  log "mac-setup.sh started (dry_run=$DRY_RUN, section=$SECTION)"
  log "========================================="

  local SECTIONS=(
    "xcode:setup_xcode"
    "homebrew:setup_homebrew"
    "taps:install_brew_taps"
    "formulae:install_brew_formulae"
    "casks:install_brew_casks"
    "mas:install_mas_apps"
    "shell:setup_shell"
    "symlinks:setup_symlinks"
    "runtimes:setup_runtime_managers"
    "tpm:setup_tpm"
    "directories:setup_directories"
    "macos:setup_macos_defaults"
    "wizard:setup_wizard"
  )

  if [ -n "$SECTION" ]; then
    local found=false
    for entry in "${SECTIONS[@]}"; do
      local name="${entry%%:*}"
      local func="${entry##*:}"
      if [ "$name" = "$SECTION" ]; then
        "$func"
        found=true
        break
      fi
    done
    if ! $found; then
      err "Unknown section: $SECTION"
      echo ""
      echo "Available sections:"
      for entry in "${SECTIONS[@]}"; do
        echo "  ${entry%%:*}"
      done
      exit 1
    fi
  else
    for entry in "${SECTIONS[@]}"; do
      local func="${entry##*:}"
      "$func"
    done
  fi

  summary
}

main
