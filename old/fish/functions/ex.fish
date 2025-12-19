# 
# ___  ____      _                _  ______              _ 
# |  \/  (_)    | |              | | | ___ \            (_)
# | .  . |_  ___| |__   __ _  ___| | | |_/ /___  ___ ___ _ 
# | |\/| | |/ __| '_ \ / _` |/ _ \ | |    // _ \/ __/ __| |
# | |  | | | (__| | | | (_| |  __/ | | |\ \ (_) \__ \__ \ |
# \_|  |_/_|\___|_| |_|\__,_|\___|_| \_| \_\___/|___/___/_|
#                                                          
#                                                          
                                                          
function ex -d "Archive extraction"
  if [ -f $argv ] ; then
    case $argv in
      *.tar.bz2)   tar xjf $argv   ;;
      *.tar.gz)    tar xzf $argv   ;;
      *.bz2)       bunzip2 $argv   ;;
      *.rar)       unrar x $argv   ;;
      *.gz)        gunzip $argv    ;;
      *.tar)       tar xf $argv    ;;
      *.tbz2)      tar xjf $argv   ;;
      *.tgz)       tar xzf $argv   ;;
      *.zip)       unzip $argv     ;;
      *.Z)         uncompress $argv;;
      *.7z)        7z x $argv      ;;
      *.deb)       ar x $argv      ;;
      *.tar.xz)    tar xf $argv    ;;
      *.tar.zst)   unzstd $argv    ;;      
      *)           echo "'$argv' cannot be extracted via ex()" ;;
    esac
  else
    echo "'$argv' is not a valid file"
  fi
end
