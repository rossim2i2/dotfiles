## Set fish initiliations

if not set -q fish_initialized

    # spark
    abbr -a clr 'clear; echo; echo; seq 1 (tput cols) | sort -R | spark | lolcat; echo; echo'

    #navigation
    abbr -a cd. 'cd ~'
    abbr -a cd.. 'cd ..'
    abbr -a .. 'cd ..'
    abbr -a ... 'cd ../..'
    abbr -a .3 'cd ../../..'
    abbr -a .4 'cd ../../../..'
    abbr -a .5 'cd ../../../../..'

    #vim
    abbr -a vim nvim

    # Changing "ls" to "exa"
    abbr -a ls 'exa -al --color=always --group-directories-first' # my preferred listing
    abbr -a la 'exa -a --color=always --group-directories-first'  # all files and dirs
    abbr -a ll 'exa -l --color=always --group-directories-first'  # long format
    abbr -a lt 'exa -aT --color=always --group-directories-first' # tree listing
    abbr -a l. 'exa -a | egrep "^\."'

    # pacman and paru
    abbr -a pacup 'sudo pacman -Syu'                    # update standard packages
    abbr -a parup 'paru -Syu'                      # update aur pakcages
    abbr -a paclean 'sudo pacman -Rns (pacman -Qtqd)'  # remove orphaned packages

    # Colorize grep output (good for log files)
    abbr -a grep 'grep --color=auto'
    abbr -a egrep 'egrep --color=auto'
    abbr -a fgrep 'fgrep --color=auto'

    # confirm before overwriting something
    abbr -a cp "cp -i"
    abbr -a mv 'mv -i'
    abbr -a rm 'rm -i'

    ## get top process eating memory
    abbr -a psmem 'ps auxf | sort -nr -k 4'
    abbr -a psmem10 'ps auxf | sort -nr -k 4 | head -10'

    ## get top process eating cpu ##
    abbr -a pscpu 'ps auxf | sort -nr -k 3'
    abbr -a pscpu10 'ps auxf | sort -nr -k 3 | head -10'

    # get error messages from journalctl
    abbr -a jctl 'journalctl -p 3 -xb'

    # bare git repo alias for dotfiles
    abbr -a config '/usr/bin/git --git-dir=$HOME/dev/dotfiles --work-tree=$HOME'
    
    # Shutdown
    abbr -a ssn 'sudo shutdown now'

    set -U fish_initialized

end
