#echo "inside bashrc"

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# make less more friendly for non-text input files, see lesspipe(1)
#[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# paramétrage de less
# Less Colors for Man Pages
export LESS_TERMCAP_mb=$'\E[01;31m'       # begin blinking
export LESS_TERMCAP_md=$'\E[01;38;5;74m'  # begin bold
export LESS_TERMCAP_me=$'\E[0m'           # end mode
export LESS_TERMCAP_se=$'\E[0m'           # end standout-mode
export LESS_TERMCAP_so=$'\E[38;5;246m'    # begin standout-mode - info box
export LESS_TERMCAP_ue=$'\E[0m'           # end underline
export LESS_TERMCAP_us=$'\E[04;38;5;146m' # begin underline

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# paramétrage de l'historique bash
# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
export HISTTIMEFORMAT='%F %T '
export HISTIGNORE='ls -l:pwd:history:ls:vim'

# to keep bash history while using tmux
# avoid duplicates..
export HISTCONTROL=ignoredups:erasedups

# append history entries..
shopt -s histappend

# After each command, save and reload history
export PROMPT_COMMAND="history -a; history -c; history -r; $PROMPT_COMMAND"
#export PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND$'\n'}history -a; history -c; history -r"

#pour ne plus avoir d'historique
#export HISTSIZE=0


# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
fi


#L'instruction du terminal pour personnaliser la couleur est ESC [ Ps m => ou Ps représente la couleur que nous voulons voir. Il peut se composer de style de fonte, couleur de premier plan et couleur d'arrière plan.

#Style de fonte:
#
#    0 default color
#    1 Bold
#    4 Underscore
#    5 Blink
#    7 Inverse
#
#Les couleurs traditionnelles sont: (black, red, green, yellow, blue, magenta, cyan, white) Les code couleurs de premier plan vont de 30 to 37 #Les code couleurs d'arrière plan vont de 40 to 47
#
#Vous pouvez mélanger les couleur du code Ps code comme 1;34;42 
#pour trouver les valeurs possible, rechercher "prompting" dans la page de manuel de bash, ainsi que les codes de dates de "strftime"
#export PS1=$'\E[1;31m'`logname`@`hostname -s`$'\E[0m:'$'\E[1;35m$PWD'$'\E[0m>'
#export PS1=$'\e[1;35m\u@\h $0 v\V\e[0m : \e[0;33m\D{%a %d %B %G} - \A\e[0m \n\e[0;35m\w'$'\e[0m\n\$ '

# powerline bash vient du site https://gitlab.com/bersace/powerline.bash
#source ~/.local/share/icons-in-terminal/icons_bash.sh
#declare -A POWERLINE_ICONS_OVERRIDES
POWERLINE_ICONS_OVERRIDES=(
    [sep]=$'\uE0BC'
    [sep-fin]=$'uE0BD'
)
POWERLINE_ICONS=icons-in-terminal
. ${HOME}/devzone/bash_config/powerline.bash/powerline.bash
POWERLINE_SEGMENTS="logo ${POWERLINE_SEGMENTS}"
PROMPT_COMMAND='__update_ps1 $?'


#add vim if running a subshell from vim
#vim_prompt() {
#  if [ ! -z $VIMRUNTIME ]; then
#    echo "inside vim ";
#  fi
#}

#export PS1='$(vim_prompt)$ '

SSH_ENV=$HOME/.ssh/environment

# start the ssh-agent
function start_agent {
# define ssh specific var
    export SSH_ASKPASS=ksshaskpass
    export SSH_ASKPASS_REQUIRE=prefer
    echo "Initializing new SSH agent from bashrc..."
    # spawn ssh-agent
    ssh-agent | sed 's/^echo/#echo/' > "${SSH_ENV}"
    echo succeeded
    chmod 600 "${SSH_ENV}"
    . "${SSH_ENV}" > /dev/null
    ssh-add
}

# test if file exist and we're not in a podman container
if [[ -f "${SSH_ENV}"  && -z $container ]]
then
     . "${SSH_ENV}" > /dev/null
     ps -ef | grep ${SSH_AGENT_PID} | grep ssh-agent$ > /dev/null || {
        start_agent;
    }
else
    echo "start agent"
    start_agent;
fi

#tmux attach
if [[ -z $TMUX ]]
then
  tmux attach-session || tmux new-session
fi

set -o vi
export VISUAL=vim
export EDITOR="$VISUAL"

