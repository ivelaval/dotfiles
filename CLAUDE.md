# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Personal dotfiles repository for macOS. Contains shell configs, editor configs, tmux setup, and bootstrap scripts for setting up a new Mac.

## Setup

- **Full Mac bootstrap**: `bash mac-setup.sh` — installs Homebrew, 50+ formulae, 35+ casks, Oh My Zsh, Powerlevel10k, Nerd Fonts, runtime managers, configures macOS defaults, and creates dotfile symlinks
- **Dry-run mode**: `bash mac-setup.sh --dry-run` — previews all actions without executing
- **Single section**: `bash mac-setup.sh --section <name>` — runs only one section (xcode, homebrew, taps, formulae, casks, mas, shell, symlinks, runtimes, tpm, directories, macos)
- **Preset environment**: `preset-mac.sh` — environment variables and PATH setup, symlinked to `~/preset-mac.sh` and sourced in shell configs
- **Tmux dev session**: `bash scripts/start-vennet-dev.sh` — creates a 4-window tmux session (editor, server, logs, git)

## Architecture

There are two generations of editor config in this repo:

1. **Legacy Vim** (`config.vim`) — vim-plug based config with CoC, NERDTree, fzf, Dracula theme. Meant to be sourced from `~/.config/nvim/init.vim`.
2. **Neovim Lua** (`nvim/`) — Packer-based Lua config under namespace `ivelaval`. Entry point is `nvim/init.lua`. Plugins are managed in `nvim/lua/ivelaval/plugins-setup.lua`. LSP is configured via Mason + lspconfig + lspsaga + null-ls.

Shell configs:
- `preset-mac.sh` — environment variables and PATH setup (Go, pnpm, Volta, .NET, asdf), sourced by `.bash_profile`
- `.bash_profile` — sources nvm, starts tmux automatically
- `zshrc` — Oh My Zsh with agnoster/Powerlevel9k theme, nvm, iTerm2 tab styling
- `zsh/` — collection of zsh themes (dracula, falkor, ghostwheel, sudhindra)

Other configs:
- `tmux.conf` — prefix remapped to `C-a`, mouse on, TPM plugins (resurrect, continuum, airline-dracula)
- `.gitconfig` — user identity and git-lfs filter
- `warp/themes/` — custom Warp terminal theme
- `scripts/pomodoro.sh` — timer aliases using `terminal-notifier` (work15/20/30/60/120, rest)

## Key Conventions

- The Neovim Lua namespace is `ivelaval` (under `nvim/lua/ivelaval/`)
- Shell environment setup lives in `preset-mac.sh`, not directly in `.bash_profile` or `zshrc`
- Tmux prefix is `C-a` (not the default `C-b`)
