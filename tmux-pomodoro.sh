#!/bin/sh
# Pomodoro segment for the tmux status bar.
#
# Wraps tmux-pomodoro-plus' own status output in a pill and prints nothing when
# no pomodoro runs, so the segment disappears instead of leaving an empty pill.
# This replaces the plugin's #{pomodoro_status} placeholder, which can only be
# given a prefix (@pomodoro_on) and so cannot carry the pill's closing cap.
# The plugin itself stays enabled in tmux.conf: it still owns the key bindings.

BAR_BG='#222436'
PILL_BG='#444a73'
FG='#ff757f'

POMODORO=$HOME/.tmux/plugins/tmux-pomodoro-plus/scripts/pomodoro.sh
[ -x "$POMODORO" ] || exit 0

status=$("$POMODORO" 2>/dev/null)
status=$(printf '%s' "$status" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
[ -n "$status" ] || exit 0

printf '#[fg=%s,bg=%s]#[fg=%s,bg=%s] %s #[fg=%s,bg=%s] \n' \
    "$PILL_BG" "$BAR_BG" "$FG" "$PILL_BG" "$status" "$PILL_BG" "$BAR_BG"
