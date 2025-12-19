# 
# ___  ____      _                _  ______              _ 
# |  \/  (_)    | |              | | | ___ \            (_)
# | .  . |_  ___| |__   __ _  ___| | | |_/ /___  ___ ___ _ 
# | |\/| | |/ __| '_ \ / _` |/ _ \ | |    // _ \/ __/ __| |
# | |  | | | (__| | | | (_| |  __/ | | |\ \ (_) \__ \__ \ |
# \_|  |_/_|\___|_| |_|\__,_|\___|_| \_| \_\___/|___/___/_|
#                                                          
#                                                          
function fs -d "Switch tmux session"
  tmux list-sessions -F "#{session_name}" | fzf | read -l result; and tmux switch-client -t "$result"
end
