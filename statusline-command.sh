#!/usr/bin/env bash
# Claude Code status line — derived from ~/.bashrc PS1 (powerline/commented variant)
# Original PS1: \e[1;35m\u@\h $0 v\V\e[0m : \e[0;33m\D{%a %d %B %G} - \A\e[0m \n\e[0;35m\w\e[0m\n\$

input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
model=$(echo "$input" | jq -r '.model.display_name // empty')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# Fallback to pwd if cwd not provided
[ -z "$cwd" ] && cwd=$(pwd)

# Build context usage indicator
ctx_info=""
if [ -n "$used" ]; then
    ctx_info=" | ctx: $(printf '%.0f' "$used")%"
fi

# Build model indicator
model_info=""
if [ -n "$model" ]; then
    model_info=" | $model"
fi

printf "\e[1;35m%s@%s\e[0m : \e[0;33m%s - %s\e[0m\n\e[0;35m%s\e[0m%s%s" \
    "$(whoami)" \
    "$(hostname -s)" \
    "$(date "+%a %d %B %Y")" \
    "$(date +%H:%M)" \
    "$cwd" \
    "$model_info" \
    "$ctx_info"
