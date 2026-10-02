#!/bin/sh
# Battery segment for the tmux status bar.
#
# Prints nothing at all while the laptop runs on AC: the icon, the percentage
# and the pill around them all disappear together, instead of leaving an empty
# "batt:" label behind. ./battery already prints nothing unless BAT0 reports
# Discharging, so the whole segment keys off its output being non-empty.
#
# Colours are the tokyonight-moon palette shared with tmux.conf:
#   pill #444a73   bar #222436   green #4fd6be   yellow #e0af68   red #ff757f

BAR_BG='#222436'
PILL_BG='#444a73'

SELF_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

level=$("$SELF_DIR/battery" Discharging 2>/dev/null)
[ -n "$level" ] || exit 0

pct=${level%\%}
case $pct in
    '' | *[!0-9]*) exit 0 ;;
esac

# nf-md battery glyphs, one per 10% step.
if   [ "$pct" -ge 95 ]; then icon='󰁹'
elif [ "$pct" -ge 85 ]; then icon='󰂂'
elif [ "$pct" -ge 75 ]; then icon='󰂁'
elif [ "$pct" -ge 65 ]; then icon='󰂀'
elif [ "$pct" -ge 55 ]; then icon='󰁿'
elif [ "$pct" -ge 45 ]; then icon='󰁾'
elif [ "$pct" -ge 35 ]; then icon='󰁽'
elif [ "$pct" -ge 25 ]; then icon='󰁼'
elif [ "$pct" -ge 15 ]; then icon='󰁻'
else                         icon='󰁺'
fi

# Warn by colour earlier than the icon shape does.
if   [ "$pct" -le 15 ]; then fg='#ff757f'
elif [ "$pct" -le 30 ]; then fg='#e0af68'
else                         fg='#4fd6be'
fi

printf '#[fg=%s,bg=%s]#[fg=%s,bg=%s] %s %s%% #[fg=%s,bg=%s] \n' \
    "$PILL_BG" "$BAR_BG" "$fg" "$PILL_BG" "$icon" "$pct" "$PILL_BG" "$BAR_BG"
