# .bash_profile

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
	. ~/.bashrc
fi

# User specific environment and startup programs
export PATH=/opt/local/bin:/opt/local/sbin:$PATH
PATH=$PATH:$HOME/devzone/bin
export PATH

# vim et MacVim par défaut
set -o vi

# définition des alias
alias ls='ls -G -p'

# paramétrage de l'historique bash
# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
export HISTTIMEFORMAT='%F %T '
export HISTCONTROL=$HISTCONTROL${HISTCONTROL+,}ignoredups
export HISTCONTROL=ignoreboth
export HISTIGNORE='ls -l:pwd:history:ls:vim'
#pour ne plus avoir d'historique
#export HISTSIZE=0

# append to the history file, don't overwrite it
shopt -s histappend

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# paramétrage de less
# Less Colors for Man Pages
export LESS_TERMCAP_mb=$'\E[01;31m'       # begin blinking
export LESS_TERMCAP_md=$'\E[01;38;5;74m'  # begin bold
export LESS_TERMCAP_me=$'\E[0m'           # end mode
export LESS_TERMCAP_se=$'\E[0m'           # end standout-mode
export LESS_TERMCAP_so=$'\E[38;5;246m'    # begin standout-mode - info box
export LESS_TERMCAP_ue=$'\E[0m'           # end underline
export LESS_TERMCAP_us=$'\E[04;38;5;146m' # begin underline

