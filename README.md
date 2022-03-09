# VIM World

This is a configuration basic of VIM for developers

## What do I need?

[Vim-Pllug] (https://github.com/junegunn/vim-plug) - Minimalist Vim Plugin Manager

### Neovim - unix

```
curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
```

Add a vim-plug section to your ` ~/.vimrc ` (or ` ~/.config/nvim/init.vim ` for Neovim):

source ~/Users/ivanavila/GitHub/vim-world/config.vim



## Tmux Plugin Manager

Clone TPM:

``` $ git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm ```

Put this at the bottom of `~/.tmux.conf` (`$XDG_CONFIG_HOME/tmux/tmux.conf`
works too):

```bash
# List of plugins
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'

# Other examples:
# set -g @plugin 'github_username/plugin_name'
# set -g @plugin 'git@github.com/user/plugin'
# set -g @plugin 'git@bitbucket.com/user/plugin'

# Initialize TMUX plugin manager (keep this line at the very bottom of tmux.conf)
run -b '~/.tmux/plugins/tpm/tpm'
```

Reload TMUX environment so TPM is sourced:

```bash
# type this in terminal if tmux is already running
$ tmux source ~/.tmux.conf
```

Install Nerd Font


## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

Please make sure to update tests as appropriate.

## License
[MIT](https://choosealicense.com/licenses/mit/)

