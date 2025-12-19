# 
# ___  ____      _                _  ______              _ 
# |  \/  (_)    | |              | | | ___ \            (_)
# | .  . |_  ___| |__   __ _  ___| | | |_/ /___  ___ ___ _ 
# | |\/| | |/ __| '_ \ / _` |/ _ \ | |    // _ \/ __/ __| |
# | |  | | | (__| | | | (_| |  __/ | | |\ \ (_) \__ \__ \ |
# \_|  |_/_|\___|_| |_|\__,_|\___|_| \_| \_\___/|___/___/_|
#                                                          
#                                                          
function fzf-select -d 'fzf commandline job and print unescaped selection back to commandline'
	set -l cmd (commandline -j)
	[ "$cmd" ]; or return
	eval $cmd | eval (__fzfcmd) -m --tiebreak=index --select-1 --exit-0 | string join ' ' | read -l result
	[ "$result" ]; and commandline -j -- $result
	commandline -f repaint
end


