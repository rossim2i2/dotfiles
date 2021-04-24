unalias -a

alias grep='grep -i --colour=auto'
alias egrep='egrep -i --colour=auto'
alias fgrep='fgrep -i --colour=auto'
alias curl='curl -L'
alias lsa='exa -al --color=always --group-directories-first'
alias ls='ls -h --color=auto'
alias '?'=duck
alias '??'=google
alias '???'=bing
alias x="exit"
alias sl="sl -e"

alias free='free -h'
alias df='df -h'
alias top="htop"

## pacman and paru
alias pacup='sudo pacman -Syu'                    # update standard packages
alias parup='paru -Syu'                           # update aur pakcages
alias paclean='sudo pacman -Rns $(pacman -Qtqd)'  # remove orphaned packages

## Shutdown
alias ssn='sudo shutdown now'

# used for bare repo (no longer used)
alias config='/usr/bin/git --git-dir=$HOME/dev/dotfiles/ --work-tree=$HOME'

which vim &>/dev/null && alias vi=vim
