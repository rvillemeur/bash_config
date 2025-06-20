# enable color support of ls and also add handy aliases
#if [ -x /usr/bin/dircolors ]; then
   test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
   alias ls='ls -G -p --color=auto'
   alias dir='dir --color=auto'
   alias vdir='vdir --color=auto'

   alias grep='grep --color=auto'
   alias fgrep='fgrep --color=auto'
   alias egrep='egrep --color=auto'
#fi

# some more ls aliases
alias ll='ls -hlrt'
alias la='ls -A'
alias l='ls -CF'

#mc alias under windows terminal and without color
alias mc='mc -b --no-x11'
