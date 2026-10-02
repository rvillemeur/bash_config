#!/usr/bin/env bash
# Claude Code status line — powerline-style solid background segments.

# ---------------------------------------------------------------------------
# ANSI helpers
# ---------------------------------------------------------------------------
C_RESET="\e[0m"

# Fedora distro segment — Fedora blue background, white foreground
BG_FEDORA="\e[48;5;26m"
FG_FEDORA="\e[97m"

# PWD segment — dark blue background, bright white foreground
BG_PWD="\e[48;5;24m"
FG_PWD="\e[97m"

# Git clean — green background, black foreground
BG_GIT_CLEAN="\e[48;5;106m"
FG_GIT_CLEAN="\e[30m"

# Git dirty — red background, white foreground
BG_GIT_DIRTY="\e[41m"
FG_GIT_DIRTY="\e[97m"

# Shared foreground colors for usage-based segments (applied to text only)
FG_USAGE_OK="\e[38;5;252m"    # light gray  — < 50 %
FG_USAGE_WARN="\e[38;5;208m"  # orange      — >= 50 %
FG_USAGE_CRIT="\e[38;5;196m"  # bright red  — >= 75 %

# Model segment — gray 237, white foreground
BG_MODEL="\e[48;5;237m"
FG_MODEL="\e[97m"

# Context segment — gray 239, fixed background
BG_CTX="\e[48;5;239m"

# Rate-limit segment — 5-hour window, gray 241, fixed background
BG_RATE5="\e[48;5;241m"

# Rate-limit segment — 7-day window, gray 243, fixed background
BG_RATE7="\e[48;5;243m"

# Powerline right-pointing solid triangle (U+E0B0 )
# The separator is rendered with:
#   • foreground = background color of the CURRENT segment  (creates the "cut" illusion)
#   • background = background color of the NEXT segment
ARROW="\xee\x82\xb0"   #

# Powerline LEFT-pointing solid triangle (U+E0B2 )
# Used by the right-hand group, where the segments grow leftwards: there the
# separator belongs on the left edge of each segment, pointing back at the one
# before it.
LEFT_ARROW="\xee\x82\xb2"   # 

# ---------------------------------------------------------------------------
# shorten_pwd <path>
#   Replaces $HOME prefix with ~, then if the result is longer than 40 chars
#   abbreviates every intermediate component to its first letter, keeping the
#   first component after ~ and the last component (basename) in full.
#   Examples:
#     ~/devzone/sources/LinuxNotes  →  ~/d/s/LinuxNotes   (if > 40 chars)
#     ~/projects/foo                →  unchanged           (if <= 40 chars)
# ---------------------------------------------------------------------------
shorten_pwd() {
    local path="$1"
    local home="$HOME"

    # Replace $HOME prefix with  (Nerd Font home icon U+F015)
    if [[ "$path" == "$home"* ]]; then
        path=$'\xef\x80\x95'"${path#$home}"
    fi

    # Only shorten if longer than 40 characters
    if [ "${#path}" -le 40 ]; then
        printf '%s' "$path"
        return
    fi

    # Split on /; handle leading ~ or /
    local prefix=""
    local rest="$path"

    local home_icon=$'\xef\x80\x95'
    if [[ "$path" == "${home_icon}/"* ]]; then
        prefix="$home_icon"
        rest="${path#${home_icon}/}"
    elif [[ "$path" == "$home_icon" ]]; then
        printf '%s' "$path"
        return
    elif [[ "$path" == "/"* ]]; then
        prefix=""
        rest="${path#/}"
    fi

    # Split rest into components
    IFS='/' read -ra parts <<< "$rest"
    local n="${#parts[@]}"

    if [ "$n" -le 2 ]; then
        # Nothing to abbreviate: first + last only, no middle
        printf '%s' "$path"
        return
    fi

    # Keep first component full, abbreviate middle ones, keep last full
    local result="$prefix/${parts[0]}"
    for (( i=1; i < n-1; i++ )); do
        result="${result}/${parts[$i]:0:1}"
    done
    result="${result}/${parts[$((n-1))]}"

    printf '%s' "$result"
}

# ---------------------------------------------------------------------------
# visible_width <string>
#   Expands the \e and \x escapes the segment strings are written with, drops
#   every SGR colour sequence, and counts what is left. Every glyph we print is
#   single-width, so the character count is the column count. Needed because
#   the right-hand group is positioned by padding, which has to know how wide
#   the two groups actually render.
# ---------------------------------------------------------------------------
visible_width() {
    local stripped
    stripped=$(printf '%b' "$1" | sed $'s/\x1b\\[[0-9;]*m//g')
    printf '%s' "${#stripped}"
}

# ---------------------------------------------------------------------------
# term_cols
#   Claude Code exports COLUMNS for the status line command and it matches the
#   pane width exactly; tput is the fallback for a manual run from a shell.
# ---------------------------------------------------------------------------
term_cols() {
    local cols="${COLUMNS:-}"
    case $cols in
        '' | *[!0-9]*) cols=$(tput cols 2>/dev/null) ;;
    esac
    case $cols in
        '' | *[!0-9]* | 0) cols=80 ;;
    esac
    printf '%s' "$cols"
}

# ---------------------------------------------------------------------------
# Read JSON input once
# ---------------------------------------------------------------------------
input=$(cat)

cwd=$(echo "$input"        | jq -r '.workspace.current_dir // .cwd // empty')
model=$(echo "$input"      | jq -r '.model.display_name // empty')
used=$(echo "$input"       | jq -r '.context_window.used_percentage // empty')

# Rate limits — 5-hour window
rate5_pct=$(echo "$input"      | jq -r '.rate_limits.five_hour.used_percentage // empty')
rate5_resets=$(echo "$input"   | jq -r '.rate_limits.five_hour.resets_at // empty')

# Rate limits — 7-day window
rate7_pct=$(echo "$input"      | jq -r '.rate_limits.seven_day.used_percentage // empty')
rate7_resets=$(echo "$input"   | jq -r '.rate_limits.seven_day.resets_at // empty')

[ -z "$cwd" ] && cwd=$(pwd)

# ---------------------------------------------------------------------------
# Write usage cache for tmux status bar
# ---------------------------------------------------------------------------
_cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/claude-code"
mkdir -p "$_cache_dir"
{
    printf 'RATE5_PCT=%s\n'    "${rate5_pct:-}"
    printf 'RATE5_RESETS=%s\n' "${rate5_resets:-}"
    printf 'RATE7_PCT=%s\n'    "${rate7_pct:-}"
    printf 'RATE7_RESETS=%s\n' "${rate7_resets:-}"
} > "$_cache_dir/usage.env.tmp" && mv "$_cache_dir/usage.env.tmp" "$_cache_dir/usage.env"

# ---------------------------------------------------------------------------
# PWD segment
# ---------------------------------------------------------------------------
short_cwd=$(shorten_pwd "$cwd")
pwd_segment="${short_cwd}"

# ---------------------------------------------------------------------------
# Git segment
# ---------------------------------------------------------------------------
git_segment=""
bg_git=""
fg_git=""
if git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null \
             || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)

    dirty=$(git -C "$cwd" status --porcelain 2>/dev/null)

    if [ -z "$dirty" ]; then
        bg_git="$BG_GIT_CLEAN"
        fg_git="$FG_GIT_CLEAN"
        git_segment="\e[31m\xee\x82\xa0${FG_GIT_CLEAN} \xe2\x9c\x94 ${branch} \xe2\x9c\x94"   #  ✔ branch ✔
    else
        staged=$(echo "$dirty"    | grep -c '^[MADRC]'  || true)
        unstaged=$(echo "$dirty"  | grep -c '^.[MD]'    || true)
        untracked=$(echo "$dirty" | grep -c '^??'       || true)
        detail=""
        [ "$staged"    -gt 0 ] && detail="${detail}+${staged}"
        [ "$unstaged"  -gt 0 ] && detail="${detail} ~${unstaged}"
        [ "$untracked" -gt 0 ] && detail="${detail} ?${untracked}"
        detail=$(echo "$detail" | sed 's/^ //')
        bg_git="$BG_GIT_DIRTY"
        fg_git="$FG_GIT_DIRTY"
        git_segment="\e[31m\xee\x82\xa0${FG_GIT_DIRTY} \xe2\x9a\xa0 ${branch} [${detail}] \xe2\x9a\xa0"   #  ⚠ branch [counts] ⚠
    fi
fi

# ---------------------------------------------------------------------------
# Model segment
# ---------------------------------------------------------------------------
model_segment=""
[ -n "$model" ] && model_segment="$model"

# ---------------------------------------------------------------------------
# Context segment
# ---------------------------------------------------------------------------
ctx_segment=""
fg_ctx=""
if [ -n "$used" ]; then
    pct=$(printf '%.0f' "$used")
    eighths=$((pct * 8 / 100))
    case $eighths in
        0) bar="\xe2\x96\x81" ;;   # ▁
        1) bar="\xe2\x96\x82" ;;   # ▂
        2) bar="\xe2\x96\x83" ;;   # ▃
        3) bar="\xe2\x96\x84" ;;   # ▄
        4) bar="\xe2\x96\x85" ;;   # ▅
        5) bar="\xe2\x96\x86" ;;   # ▆
        6) bar="\xe2\x96\x87" ;;   # ▇
        *)  bar="\xe2\x96\x88" ;;  # █
    esac
    ctx_segment="ctx${bar}${pct}%"

    if [ "$pct" -ge 75 ]; then
        fg_ctx="$FG_USAGE_CRIT"
    elif [ "$pct" -ge 50 ]; then
        fg_ctx="$FG_USAGE_WARN"
    else
        fg_ctx="$FG_USAGE_OK"
    fi
fi

# ---------------------------------------------------------------------------
# 5-hour rate-limit segment
# ---------------------------------------------------------------------------
rate5_segment=""
fg_rate5=""
if [ -n "$rate5_pct" ]; then
    r5=$(printf '%.0f' "$rate5_pct")
    reset5_str=""
    if [ -n "$rate5_resets" ]; then
        now=$(date +%s)
        diff=$(( rate5_resets - now ))
        if [ "$diff" -gt 0 ]; then
            h=$(( diff / 3600 ))
            m=$(( (diff % 3600) / 60 ))
            reset5_str=" \xe2\x86\xba${h}h${m}m"   # ↺XhYm
        fi
    fi
    rate5_segment="5h:${r5}%${reset5_str}"

    if [ "$r5" -ge 75 ]; then
        fg_rate5="$FG_USAGE_CRIT"
    elif [ "$r5" -ge 50 ]; then
        fg_rate5="$FG_USAGE_WARN"
    else
        fg_rate5="$FG_USAGE_OK"
    fi
fi

# ---------------------------------------------------------------------------
# 7-day rate-limit segment
# ---------------------------------------------------------------------------
rate7_segment=""
fg_rate7=""
if [ -n "$rate7_pct" ]; then
    r7=$(printf '%.0f' "$rate7_pct")
    reset7_str=""
    if [ -n "$rate7_resets" ]; then
        now=$(date +%s)
        diff7=$(( rate7_resets - now ))
        if [ "$diff7" -gt 0 ]; then
            d7=$(( diff7 / 86400 ))
            h7=$(( (diff7 % 86400) / 3600 ))
            if [ "$d7" -gt 0 ]; then
                reset7_str=" \xe2\x86\xba${d7}d${h7}h"   # ↺XdYh
            else
                m7=$(( (diff7 % 3600) / 60 ))
                reset7_str=" \xe2\x86\xba${h7}h${m7}m"   # ↺XhYm
            fi
        fi
    fi
    rate7_segment="7d:${r7}%${reset7_str}"

    if [ "$r7" -ge 75 ]; then
        fg_rate7="$FG_USAGE_CRIT"
    elif [ "$r7" -ge 50 ]; then
        fg_rate7="$FG_USAGE_WARN"
    else
        fg_rate7="$FG_USAGE_OK"
    fi
fi

# ---------------------------------------------------------------------------
# Assemble the powerline line
#
# We build an ordered list of active segments, each carrying:
#   seg_text[]   — the printable content
#   seg_bg[]     — background escape code for that segment
#   seg_fg[]     — foreground escape code for that segment
#
# The powerline trick for each arrow between segment i and i+1:
#   set background to seg_bg[i+1], foreground to a "dark echo" of seg_bg[i],
#   then print the arrow glyph, then switch to seg_fg[i+1] for content.
#
# After the last segment we reset and print a final arrow with fg = last seg_bg
# so the segment appears to "end" cleanly into the terminal background.
#
# Because ANSI background codes cannot easily be turned into matching foreground
# codes numerically at runtime, we pair each segment background with an explicit
# "dark-fg" colour that visually matches it (used only for the trailing arrow).
# ---------------------------------------------------------------------------

# Parallel arrays: index -> (text, bg, fg, dark_fg_for_trailing_arrow)
# Two groups now: the identity of the shell on the left, the Claude usage
# meters on the right, pushed to the far edge and separated by blank space.
seg_text=()
seg_bg=()
seg_fg=()
seg_trailing_fg=()   # foreground colour that visually matches the segment bg

# Same four arrays for the right-hand group.
rseg_text=()
rseg_bg=()
rseg_fg=()
rseg_trailing_fg=()

# --- Left group -----------------------------------------------------------

# Fedora distro icon — always present (U+F30A )
seg_text+=( $'\xef\x8c\x8a' )
seg_bg+=( "${BG_FEDORA}" )
seg_fg+=( "${FG_FEDORA}" )
seg_trailing_fg+=( "\e[38;5;26m" )   # Fedora blue fg echoes Fedora blue bg

# PWD — always present
seg_text+=( "${pwd_segment}" )
seg_bg+=( "${BG_PWD}" )
seg_fg+=( "${FG_PWD}" )
seg_trailing_fg+=( "\e[38;5;24m" )   # color-24 fg echoes color-24 bg (BG_PWD)

# Git — optional
if [ -n "$git_segment" ]; then
    seg_text+=( "${git_segment}" )
    seg_bg+=( "${bg_git}" )
    seg_fg+=( "${fg_git}" )
    if [ "$bg_git" = "$BG_GIT_CLEAN" ]; then
        seg_trailing_fg+=( "\e[38;5;106m" )   # color-106 fg echoes color-106 bg (BG_GIT_CLEAN)
    else
        seg_trailing_fg+=( "\e[31m" )   # red fg echoes red bg
    fi
fi

# Model — optional. It says which model is answering, not how much is left, so
# it stays with the identity group. Move the three lines into the rseg_* arrays
# below to park it with the usage meters instead.
if [ -n "$model_segment" ]; then
    seg_text+=( "${model_segment}" )
    seg_bg+=( "${BG_MODEL}" )
    seg_fg+=( "${FG_MODEL}" )
    seg_trailing_fg+=( "\e[38;5;237m" )   # gray-237 fg echoes gray-237 bg (BG_MODEL)
fi

# --- Right group: the Claude usage meters ---------------------------------

# Context — optional
if [ -n "$ctx_segment" ]; then
    rseg_text+=( "${ctx_segment}" )
    rseg_bg+=( "${BG_CTX}" )
    rseg_fg+=( "${fg_ctx}" )
    rseg_trailing_fg+=( "\e[38;5;239m" )   # gray-239 fg echoes gray-239 bg (BG_CTX)
fi

# 5-hour rate limit — optional
if [ -n "$rate5_segment" ]; then
    rseg_text+=( "${rate5_segment}" )
    rseg_bg+=( "${BG_RATE5}" )
    rseg_fg+=( "${fg_rate5}" )
    rseg_trailing_fg+=( "\e[38;5;241m" )   # gray-241 fg echoes gray-241 bg (BG_RATE5)
fi

# 7-day rate limit — optional
if [ -n "$rate7_segment" ]; then
    rseg_text+=( "${rate7_segment}" )
    rseg_bg+=( "${BG_RATE7}" )
    rseg_fg+=( "${fg_rate7}" )
    rseg_trailing_fg+=( "\e[38;5;243m" )   # gray-243 fg echoes gray-243 bg (BG_RATE7)
fi

# --- Render the left group ------------------------------------------------
n="${#seg_text[@]}"
line=""

for (( i=0; i<n; i++ )); do
    if [ "$i" -eq 0 ]; then
        # First segment: open with its background + foreground, then content
        line="${line}${seg_bg[$i]}${seg_fg[$i]} ${seg_text[$i]} "
    else
        # Arrow transition: bg of THIS segment, fg echoes bg of PREVIOUS segment
        line="${line}${seg_bg[$i]}${seg_trailing_fg[$((i-1))]}${ARROW}${seg_fg[$i]} ${seg_text[$i]} "
    fi
done

# Trailing arrow after the last segment (terminal background, no bg set)
line="${line}${C_RESET}${seg_trailing_fg[$((n-1))]}${ARROW}${C_RESET}"

# --- Render the right group -----------------------------------------------
#
# Mirror image of the loop above. The separator is LEFT_ARROW and it is painted
# in the colour of the segment it introduces, over the background of whatever
# sits to its left: the terminal itself for the first one, the previous segment
# for the rest. That makes each arrow read as that segment's left edge.
m="${#rseg_text[@]}"
right=""

for (( j=0; j<m; j++ )); do
    if [ "$j" -eq 0 ]; then
        right="${right}${C_RESET}${rseg_trailing_fg[$j]}${LEFT_ARROW}${rseg_bg[$j]}${rseg_fg[$j]} ${rseg_text[$j]} "
    else
        right="${right}${rseg_bg[$((j-1))]}${rseg_trailing_fg[$j]}${LEFT_ARROW}${rseg_bg[$j]}${rseg_fg[$j]} ${rseg_text[$j]} "
    fi
done
[ "$m" -gt 0 ] && right="${right}${C_RESET}"

# --- Place the two groups -------------------------------------------------
#
# No usage data (a fresh session, or an older Claude Code that does not send
# rate_limits) means there is no right group at all, so print the left one and
# stop. Otherwise pad between them, stopping one column short of the edge so a
# terminal with automatic margins cannot wrap the line. If the two groups do
# not fit, fall back to a single space: Claude Code truncates, which beats
# silently wrapping onto a second row.
if [ "$m" -eq 0 ]; then
    printf '%b' "$line"
    exit 0
fi

cols=$(term_cols)
gap=$(( cols - 1 - $(visible_width "$line") - $(visible_width "$right") ))
[ "$gap" -lt 1 ] && gap=1

printf '%b%*s%b' "$line" "$gap" "" "$right"
