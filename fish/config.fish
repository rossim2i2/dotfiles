# 
# ___  ____      _                _  ______              _ 
# |  \/  (_)    | |              | | | ___ \            (_)
# | .  . |_  ___| |__   __ _  ___| | | |_/ /___  ___ ___ _ 
# | |\/| | |/ __| '_ \ / _` |/ _ \ | |    // _ \/ __/ __| |
# | |  | | | (__| | | | (_| |  __/ | | |\ \ (_) \__ \__ \ |
# \_|  |_/_|\___|_| |_|\__,_|\___|_| \_| \_\___/|___/___/_|
#                                                          
#                                                          
## My fish config. Not much to see here; just some pretty standard stuff.

# These go first, because other stuff depends on them.
set -gx XDG_CACHE_HOME $HOME/.cache
set -gx XDG_CONFIG_HOME $HOME/.config
set -gx XDG_DATA_HOME $HOME/.local/share

set fish_greeting                                                           # Supresses fish's intro message
set TERM "xterm-256color"                                                   # Sets the terminal type

### EXPORT ###
if not set -q fish_user_paths
    set -U fish_user_paths ~/.local/bin
end

## SET EITHER DEFAULT EMACS MODE OR VI MODE ###
function fish_user_key_bindings
  # fish_default_key_bindings
  # fish_vi_key_bindings
  fzf_key_bindings 
end
### END OF VI MODE ###

# Source function files as needed
source $HOME/.config/fish/functions/bang.fish

neofetch
