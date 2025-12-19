# 
# ___  ____      _                _  ______              _ 
# |  \/  (_)    | |              | | | ___ \            (_)
# | .  . |_  ___| |__   __ _  ___| | | |_/ /___  ___ ___ _ 
# | |\/| | |/ __| '_ \ / _` |/ _ \ | |    // _ \/ __/ __| |
# | |  | | | (__| | | | (_| |  __/ | | |\ \ (_) \__ \__ \ |
# \_|  |_/_|\___|_| |_|\__,_|\___|_| \_| \_\___/|___/___/_|
#                                                          
#                                                          
function pacfind -d "find packages in pacman"
    pacman -Slq | fzf --multi --preview 'cat <(pacman -Si $argv) <(pacman -Fl $argv | awk "{print \$2}")' | xargs -ro sudo pacman -S
end
