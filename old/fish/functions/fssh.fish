# 
# ___  ____      _                _  ______              _ 
# |  \/  (_)    | |              | | | ___ \            (_)
# | .  . |_  ___| |__   __ _  ___| | | |_/ /___  ___ ___ _ 
# | |\/| | |/ __| '_ \ / _` |/ _ \ | |    // _ \/ __/ __| |
# | |  | | | (__| | | | (_| |  __/ | | |\ \ (_) \__ \__ \ |
# \_|  |_/_|\___|_| |_|\__,_|\___|_| \_| \_\___/|___/___/_|
#                                                          
#                                                          
function fssh -d "Fuzzy-find ssh host via ag and ssh into it"
  ag --ignore-case '^host [^*]' ~/.ssh/config | cut -d ' ' -f 2 | fzf | read -l result; and ssh "$result"
end
