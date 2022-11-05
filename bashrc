#echo "inside bashrc"
# If not running interactively, don't do anything
#[ -z "$PS1" ] && return

# make less more friendly for non-text input files, see lesspipe(1)
#[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

#if [ -f ~/.bash_aliases ]; then
#    . ~/.bash_aliases
#fi

# enable color support of ls and also add handy aliases
#if [ -x /usr/bin/dircolors ]; then
   test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
   alias ls='ls --color=auto'
   alias dir='dir --color=auto'
   alias vdir='vdir --color=auto'

   alias grep='grep --color=auto'
   alias fgrep='fgrep --color=auto'
   alias egrep='egrep --color=auto'
#fi

# some more ls aliases
alias ll='ls -l'
alias la='ls -A'
alias l='ls -CF'

#mc alias under windows terminal
alias mc='mc --no-x11'

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
fi

SSH_ENV=$HOME/.ssh/environment

# start the ssh-agent
function start_agent {
    echo "Initializing new SSH agent..."
    # spawn ssh-agent
    /usr/bin/ssh-agent | sed 's/^echo/#echo/' > "${SSH_ENV}"
    echo succeeded
    chmod 600 "${SSH_ENV}"
    . "${SSH_ENV}" > /dev/null
    /usr/bin/ssh-add
}

if [ -f "${SSH_ENV}" ]; then
     . "${SSH_ENV}" > /dev/null
     ps -ef | grep ${SSH_AGENT_PID} | grep ssh-agent$ > /dev/null || {
        start_agent;
    }
else
    start_agent;
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
. ${HOME}/devzone/bash_config/powerline.bash
PROMPT_COMMAND='__update_ps1 $?'

#tmux attach
if [[ -z $TMUX ]]; then
  tmux attach-session || tmux new-session
fi

set -o vi
export VISUAL=vim
export EDITOR="$VISUAL"
