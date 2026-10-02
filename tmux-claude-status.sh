#!/usr/bin/env bash
# Claude Code usage segments for tmux status-right.
# Reads from cache written by statusline-command.sh; recomputes countdowns live.

cache="${XDG_CACHE_HOME:-$HOME/.cache}/claude-code/usage.env"
[ -f "$cache" ] || exit 0

# shellcheck disable=SC1090
source "$cache"

now=$(date +%s)

# Palette shared with tmux.conf (tokyonight-moon).
BAR_BG='#222436'
PILL_BG='#444a73'
CAP_L=''
CAP_R=''

_fg() {
    local pct=$1
    if   [ "$pct" -ge 75 ]; then printf '#ff757f'   # red
    elif [ "$pct" -ge 50 ]; then printf '#e0af68'   # yellow
    else                         printf '#828bb8'   # dim foreground
    fi
}

# _pill <text_fg> <text>
#   One rounded segment, matching the pills on status-right: a cap in the pill
#   colour over the bar background, the body, then the closing cap. One #[]
#   directive per attribute, never "fg=x,bg=y", so the output stays safe to drop
#   inside a tmux #{?...} conditional, which splits on the first comma.
_pill() {
    printf '#[fg=%s]#[bg=%s]%s#[fg=%s]#[bg=%s] %s #[fg=%s]#[bg=%s]%s' \
        "$PILL_BG" "$BAR_BG" "$CAP_L" \
        "$1" "$PILL_BG" "$2" \
        "$PILL_BG" "$BAR_BG" "$CAP_R"
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
        printf ' \u21ba%dd%dh' "$d" "$h"
    else
        printf ' \u21ba%dh%dm' "$h" "$m"
    fi
}

out=""

# 5-hour window: hourglass icon.
if [ -n "$RATE5_PCT" ]; then
    r5=$(printf '%.0f' "$RATE5_PCT")
    cd5=$(_countdown "$RATE5_RESETS")
    out="${out}$(_pill "$(_fg "$r5")" "$(printf '%b' "󰔟 5h ${r5}%${cd5}")")"
fi

# 7-day window: calendar icon.
if [ -n "$RATE7_PCT" ]; then
    r7=$(printf '%.0f' "$RATE7_PCT")
    cd7=$(_countdown "$RATE7_RESETS")
    [ -n "$out" ] && out="${out} "
    out="${out}$(_pill "$(_fg "$r7")" "$(printf '%b' "󰃭 7d ${r7}%${cd7}")")"
fi

# Pad the group so the caps never touch the window list on the left or the
# status-right segments on the right. The pad is U+00A0, not a plain space:
# tmux trims ASCII whitespace at the edges of an #[align=...] block, and this
# output is exactly such an edge, so a normal space here is silently dropped.
NBSP=' '
[ -n "$out" ] && out="${NBSP}${out}${NBSP}"

printf '%s' "$out"
