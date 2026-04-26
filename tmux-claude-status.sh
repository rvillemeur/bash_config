#!/usr/bin/env bash
# Claude Code usage segments for tmux status-right.
# Reads from cache written by statusline-command.sh; recomputes countdowns live.

cache="${XDG_CACHE_HOME:-$HOME/.cache}/claude-code/usage.env"
[ -f "$cache" ] || exit 0

# shellcheck disable=SC1090
source "$cache"

now=$(date +%s)

_fg() {
    local pct=$1
    if   [ "$pct" -ge 75 ]; then printf 'colour196'   # bright red
    elif [ "$pct" -ge 50 ]; then printf 'colour208'   # orange
    else                         printf 'colour252'   # light gray
    fi
}

_countdown() {
    local resets=$1
    [ -z "$resets" ] && return
    local diff=$(( resets - now ))
    [ "$diff" -le 0 ] && return
    local d=$(( diff / 86400 ))
    local h=$(( (diff % 86400) / 3600 ))
    local m=$(( (diff % 3600) / 60 ))
    if [ "$d" -gt 0 ]; then
        printf ' ↺%dd%dh' "$d" "$h"
    else
        printf ' ↺%dh%dm' "$h" "$m"
    fi
}

out=""

if [ -n "$RATE5_PCT" ]; then
    r5=$(printf '%.0f' "$RATE5_PCT")
    fg5=$(_fg "$r5")
    cd5=$(_countdown "$RATE5_RESETS")
    out="${out}#[bg=colour241,fg=${fg5}] Session:${r5}%${cd5} #[default]"
fi

if [ -n "$RATE7_PCT" ]; then
    r7=$(printf '%.0f' "$RATE7_PCT")
    fg7=$(_fg "$r7")
    cd7=$(_countdown "$RATE7_RESETS")
    out="${out}#[bg=colour243,fg=${fg7}] Weekly:${r7}%${cd7} #[default]"
fi

printf '%s' "$out"
