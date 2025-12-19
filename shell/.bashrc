#!/bin/bash
# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# Enable bash programmable completion features in interactive shells
if [ -f /usr/share/bash-completion/bash_completion ]; then
	. /usr/share/bash-completion/bash_completion
elif [ -f /etc/bash_completion ]; then
	. /etc/bash_completion
fi

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]; then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# User specific aliases and functions if [ -d ~/.bashrc.d ]; then
    for rc in ~/.bashrc.d/*; do
        if [ -f "$rc" ]; then
            . "$rc"
        fi
    done

unset rc

# ---------------------- local utility functions ---------------------

_have() { type "$1" &>/dev/null; }
_source_if() { [[ -r "$1" ]] && source "$1"; }

# ----------------------------- dircolors ----------------------------

if command -v dircolors &>/dev/null; then
  eval "$(dircolors -b ~/.dircolors-tokyonight)"
fi

# ------------------------ bash shell options ------------------------

shopt -s checkwinsize
shopt -s expand_aliases
shopt -s globstar
shopt -s dotglob
shopt -s extglob

# ------------------------------ history -----------------------------

export HISTCONTROL=ignoreboth
export HISTSIZE=5000
export HISTFILESIZE=10000
export PAGER="less -FRSX"

set -o vi
shopt -s histappend

# ----------------------- environment variables ----------------------
#                           (also see envx)

export USER="${USER:-$(whoami)}"
export GITUSER="$USER"
export REPOS="$HOME/Repos"
export GHREPOS="$REPOS/github.com/$GITUSER"
export DOTFILES="$GHREPOS/dotfiles"
export SCRIPTS="$DOTFILES/scripts"
export SNIPPETS="$DOTFILES/snippets"
export EDITOR=nvim
export VISUAL=nvim
export EDITOR_PREFIX=nvim
export TERM=xterm-256color
export ZK_NOTEBOOK_DIR="$GHREPOS/zet"

eval "$(dircolors -b)"

[[ -d /.vim/spell ]] && export VIMSPELL=("$HOME/.vim/spell/*.add")

# ------------------------------- path -------------------------------

pathappend() {
  declare arg
  for arg in "$@"; do
    test -d "$arg" || continue
    PATH=${PATH//":$arg:"/:}
    PATH=${PATH/#"$arg:"/}
    PATH=${PATH/%":$arg"/}
    export PATH="${PATH:+"$PATH:"}$arg"
  done
} && export pathappend

pathprepend() {
  for arg in "$@"; do
    test -d "$arg" || continue
    PATH=${PATH//:"$arg:"/:}
    PATH=${PATH/#"$arg:"/}
    PATH=${PATH/%":$arg"/}
    export PATH="$arg${PATH:+":${PATH}"}"
  done
} && export pathprepend

# remember last arg will be first in path
pathprepend \
  /usr/local/bin \
  "$HOME/.local/bin" \
  "$GHREPOS/cmd-"* \
  "$SCRIPTS"

pathappend \
  /usr/local/opt/coreutils/libexec/gnubin \
  '/mnt/c/Program Files/Oracle/VirtualBox' \
  '/mnt/c/Windows' \
  '/mnt/c/Program Files (x86)/VMware/VMware Workstation' \
  /mingw64/bin \
  /usr/local/bin \
  /usr/local/go/bin \
  /usr/local/sbin \
  /usr/local/games \
  /usr/games \
  /usr/sbin \
  /usr/bin \
  /snap/bin \
  /sbin \
  /bin

# ------------------------------ cdpath ------------------------------

export CDPATH=".:$GHREPOS:$RWXREPOS:$DOTFILES:$REPOS:/media/$USER:$HOME"

# --------------------------- smart prompt ---------------------------
#                 (keeping in bashrc for portability)

PROMPT_LONG=20
PROMPT_MAX=95
PROMPT_AT=@

__ps1() {
  local P='$' dir="${PWD##*/}" B countme short long double\
    r g h u p w b x

  # Tokyo Night Night colors (truecolor)
  r='\[\e[38;2;247;118;142m\]'  # red      (#f7768e)  - errors / root / hot branches
  g='\[\e[38;2;169;177;214m\]'  # dim fg   (#a9b1d6)  - box lines / separators
  h='\[\e[38;2;122;162;247m\]'  # blue     (#7aa2f7)  - host
  u='\[\e[38;2;187;154;247m\]'  # magenta  (#bb9af7)  - user
  p='\[\e[38;2;125;207;255m\]'  # cyan     (#7dcfff)  - prompt symbol
  w='\[\e[38;2;224;175;104m\]'  # yellow   (#e0af68)  - cwd
  b='\[\e[38;2;125;207;255m\]'  # cyan     (#7dcfff)  - git branch
  x='\[\e[0m\]'                 # reset

  [[ $EUID == 0 ]] && P='#' && u=$r && p=$u  # root: user + prompt go red
  [[ $PWD = / ]] && dir=/
  [[ $PWD = "$HOME" ]] && dir='~'

  B=$(git branch --show-current 2>/dev/null)
  [[ $dir = "$B" ]] && B=.
  countme="$USER$PROMPT_AT$(hostname):$dir($B)\$ "

  # Hot branches (master/main) → red
  [[ $B = master || $B = main ]] && b="$r"
  [[ -n "$B" ]] && B="$g($b$B$g)"

  short="$u\u$g$PROMPT_AT$h\h$g:$w$dir$B$p$P$x "
  long="$g╔ $u\u$g$PROMPT_AT$h\h$g:$w$dir$B\n$g╚ $p$P$x "
  double="$g╔ $u\u$g$PROMPT_AT$h\h$g:$w$dir\n$g║ $B\n$g╚ $p$P$x "

  if (( ${#countme} > PROMPT_MAX )); then
    PS1="$double"
  elif (( ${#countme} > PROMPT_LONG )); then
    PS1="$long"
  else
    PS1="$short"
  fi
}

PROMPT_COMMAND="__ps1"

# ----------------------------- keyboard -----------------------------

_have setxkbmap && test -n "$DISPLAY" && \
  setxkbmap -option caps:escape &>/dev/null

# ------------------------------ aliases -----------------------------

unalias -a
alias dot='cd $DOTFILES'
alias scripts='cd $SCRIPTS'
alias snippets='cd $SNIPPETS'
alias cat="bat"
alias free="free -h"
alias df="df -h"
alias clear='printf "\e[H\e[2J"'
alias c='printf "\e[H\e[2J"'
alias x="exit"
#alias rm='trash -v'
alias vi='nvim'
alias vim='nvim'

# Change directory aliases
alias home='cd ~'
alias cd..='cd ..'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

# Alias's for multiple directory listing commands
alias la='ls -Alh'                # show hidden files
alias ls='ls -aFh --color=always' # add colors and file type extensions
alias lx='ls -lXBh'               # sort by extension
alias lk='ls -lSrh'               # sort by size
alias lc='ls -ltcrh'              # sort by change time
alias lu='ls -lturh'              # sort by access time
alias lr='ls -lRh'                # recursive ls
alias lt='ls -ltrh'               # sort by date
alias lm='ls -alh |more'          # pipe through 'more'
alias lw='ls -xAh'                # wide listing format
alias ll='ls -Fls'                # long listing format
alias labc='ls -lap'              # alphabetical sort
alias lf="ls -l | egrep -v '^d'"  # files only
alias ldir="ls -l | egrep '^d'"   # directories only
alias lla='ls -Al'                # List and Hidden Files
alias las='ls -A'                 # Hidden Files
alias lls='ls -l'                 # List

