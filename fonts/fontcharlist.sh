#!/bin/bash -

# ./fontcharlist.sh /usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf
# bash fontcharlist.sh ~/.local/share/fonts/CaskaydiaCove/CaskaydiaMonoNerdFontMono-Regular.ttf | more
#
# less shows private use characters (Nerd Font icons) as <U+XXXX>. Tell less
# they are printable:
# bash fontcharlist.sh font.ttf | LESSUTFCHARDEF='e000-f8ff:p,f0000-10fffd:p' less -S
#
# -e asks for the color emoji version of every emoji. Terminals do not agree
# on the width of these emoji, so -e first asks the terminal how many cells it
# uses for one, and pads the table to that width:
# bash fontcharlist.sh -e font.ttf | LESSUTFCHARDEF='e000-f8ff:p,f0000-10fffd:p' less -S
#
# -a lists all emoji, whatever the font, in color (it implies -e). No font
# file is given:
# bash fontcharlist.sh -a | less -S

Usage() {
    echo "Usage: $0 [-e] FontFile [Columns]" >&2
    echo "       $0 -a [Columns]" >&2
    exit 1
}
SayError() { local error=$1; shift; echo "$0: $*" >&2; exit "$error"; }

emoji=0 allemoji=0
while getopts ea option; do
    case $option in
        e) emoji=1 ;;
        a) allemoji=1 emoji=1 ;;
        *) Usage ;;
    esac
done
shift $((OPTIND - 1))

if ((allemoji)); then
    [ "$#" -gt 1 ] && Usage
    columns="${1:-6}"
else
    [ "$#" -lt 1 ] || [ "$#" -gt 2 ] && Usage
    fontfile="$1"
    columns="${2:-6}"
    [ -f "$fontfile" ] || SayError 4 'File not found'
    command -v fc-query >/dev/null || SayError 5 'fc-query not installed'
fi

[[ "$columns" =~ ^[1-9][0-9]*$ ]] || SayError 2 'Columns must be a positive integer'

# Code point classes, as sorted "start end" pairs in hexadecimal. They are an
# approximation of the Unicode data, enough to keep the table aligned.
# invisible: controls, format characters (bidi controls, zero width space,
#            ...), line/paragraph separators and surrogates. Shown as a dot.
invisible=(0 1F 7F 9F AD AD 600 605 61C 61C 6DD 6DD 70F 70F 180E 180E
    200B 200F 2028 202E 2060 206F D800 DFFF FEFF FEFF FFF9 FFFB E0000 E007F)
# combining: marks drawn on the previous character, and Hangul medial and
# final jamo. Shown on a dotted circle.
combining=(300 36F 483 489 591 5BD 5BF 5BF 5C1 5C2 5C4 5C5 5C7 5C7 610 61A
    64B 65F 670 670 6D6 6DC 6DF 6E4 6E7 6E8 6EA 6ED 1160 11FF 1AB0 1AFF
    1DC0 1DFF 20D0 20FF 302A 302F 3099 309A FE00 FE0F FE20 FE2F E0100 E01EF)
# rtl: right-to-left scripts. Followed by a LEFT-TO-RIGHT MARK so that a
# bidi-aware terminal does not reorder the row.
rtl=(590 8FF FB1D FDFF FE70 FEFE 10800 10FFF 1E800 1EFFF)
# textemoji: emoji drawn as monochrome text by default, on 1 cell. With -e,
# they are followed by VARIATION SELECTOR-16 to ask for the color emoji,
# drawn on 2 cells.
textemoji=(A9 A9 AE AE 203C 203C 2049 2049 2122 2122 2139 2139 2194 2199
    21A9 21AA 2328 2328 23CF 23CF 23ED 23EF 23F1 23F2 23F8 23FA 24C2 24C2
    25AA 25AB 25B6 25B6 25C0 25C0 25FB 25FC 2600 2604 260E 260E 2611 2611
    2618 2618 261D 261D 2620 2620 2622 2623 2626 2626 262A 262A 262E 262F
    2638 263A 2640 2640 2642 2642 265F 2660 2663 2663 2665 2666 2668 2668
    267B 267B 267E 267E 2692 2692 2694 2697 2699 2699 269B 269C 26A0 26A0
    26A7 26A7 26B0 26B1 26C8 26C8 26CF 26CF 26D1 26D1 26D3 26D3 26E9 26E9
    26F0 26F1 26F4 26F4 26F7 26F9 2702 2702 2708 2709 270C 270D 270F 270F
    2712 2712 2714 2714 2716 2716 271D 271D 2721 2721 2733 2734 2744 2744
    2747 2747 2763 2764 27A1 27A1 2934 2935 2B05 2B07 3030 3030 303D 303D
    3297 3297 3299 3299 1F170 1F171 1F17E 1F17F 1F202 1F202 1F237 1F237
    1F321 1F321 1F324 1F32C 1F336 1F336 1F37D 1F37D 1F396 1F397 1F399 1F39B
    1F39E 1F39F 1F3CB 1F3CE 1F3D4 1F3DF 1F3F3 1F3F3 1F3F5 1F3F5 1F3F7 1F3F7
    1F43F 1F43F 1F441 1F441 1F4FD 1F4FD 1F549 1F54A 1F56F 1F570 1F573 1F579
    1F587 1F587 1F58A 1F58D 1F590 1F590 1F5A5 1F5A5 1F5A8 1F5A8 1F5B1 1F5B2
    1F5BC 1F5BC 1F5C2 1F5C4 1F5D1 1F5D3 1F5DC 1F5DE 1F5E1 1F5E1 1F5E3 1F5E3
    1F5E8 1F5E8 1F5EF 1F5EF 1F5F3 1F5F3 1F5FA 1F5FA 1F6CB 1F6CB 1F6CD 1F6CF
    1F6E0 1F6E5 1F6E9 1F6E9 1F6F0 1F6F0 1F6F3 1F6F3)
# wide: characters drawn on 2 terminal cells (CJK, fullwidth forms, emoji).
# With -e, the emoji are followed by VARIATION SELECTOR-16, so that the
# terminal uses the color emoji font instead of the font's own glyph.
wide=(1100 115F 231A 231B 2329 232A 23E9 23EC 23F0 23F0 23F3 23F3 25FD 25FE
    2614 2615 2648 2653 267F 267F 2693 2693 26A1 26A1 26AA 26AB 26BD 26BE
    26C4 26C5 26CE 26CE 26D4 26D4 26EA 26EA 26F2 26F3 26F5 26F5 26FA 26FA
    26FD 26FD 2705 2705 270A 270B 2728 2728 274C 274C 274E 274E 2753 2755
    2757 2757 2795 2797 27B0 27B0 27BF 27BF 2B1B 2B1C 2B50 2B50 2B55 2B55
    2E80 303E 3041 33FF 3400 4DBF 4E00 9FFF A000 A4CF A960 A97F AC00 D7A3
    F900 FAFF FE10 FE19 FE30 FE6F FF00 FF60 FFE0 FFE6 16FE0 1B2FF
    1F004 1F004 1F0CF 1F0CF 1F18E 1F18E 1F191 1F19A 1F200 1F251 1F300 1F64F
    1F680 1F6FF 1F7E0 1F7EB 1F90C 1F9FF 1FA70 1FAFF 20000 3FFFD)

# Converts a class array from hexadecimal to decimal, in place.
ToDecimal() { local -n ranges=$1; local k; for k in "${!ranges[@]}"; do ranges[k]=$((16#${ranges[k]})); done; }
for class in invisible combining textemoji rtl wide; do ToDecimal "$class"; done

# Succeeds when code point $i is in one of the ranges of the class named $1.
InClass() {
    local -n ranges=$1
    local k
    for ((k=0; k<${#ranges[@]}; k+=2)); do
        ((i < ranges[k])) && return 1
        ((i <= ranges[k+1])) && return 0
    done
    return 1
}

# Succeeds when code point $i is in a block that holds emoji. It separates the
# wide emoji from the other wide characters (CJK, fullwidth forms, and the
# angle brackets U+2329 and U+232A).
InEmojiBlock() { ((i >= 0x2300 && i <= 0x2BFF && (i < 0x2329 || i > 0x232A) || i >= 0x1F000 && i <= 0x1FAFF)); }

placeholder=$'·'
dottedcircle=$'◌'
lrm=$'‎'
vs16=$'️'

# Opens the terminal on file descriptor 3 to measure glyph widths. tty stays 0
# when there is no terminal.
tty=0
((emoji)) && { exec 3<>/dev/tty; } 2>/dev/null && tty=1

# Sets the variable named $1 to the number of cells the terminal uses for the
# text $2. It prints the text at the start of the line on /dev/tty, asks for
# the cursor position (ESC [ 6 n), reads the answer (ESC [ row ; column R),
# then erases the line. When there is no terminal or no answer, the variable
# is set to the default width $3, the width given by the Unicode standard.
MeasureWidth() {
    local -n measured=$1
    local answer row column
    measured=$3
    ((tty)) || return
    printf '\r%s\e[6n' "$2" >&3
    if IFS='[;' read -rs -d R -t 1 -u 3 answer row column; then
        ((column >= 2 && column <= 9)) && measured=$((column - 1))
    fi
    printf '\r\e[K' >&3
}
# emojiwidth: a text emoji followed by VARIATION SELECTOR-16.
((emoji)) && MeasureWidth emojiwidth $'☺️' 2
if ((allemoji)); then
# flagwidth: a pair of regional indicators. tonewidth: an emoji followed by a
# skin tone modifier. zwjwidth: emoji joined by ZERO WIDTH JOINER.
    MeasureWidth flagwidth $'\U1f1eb\U1f1f7' 2
    MeasureWidth tonewidth $'\U1f44b\U1f3fb' 2
    MeasureWidth zwjwidth $'\U1f3f4‍☠️' 2
fi
((tty)) && exec 3>&-

if ((allemoji)); then
# Builds the list of all emoji ranges, in the fc-query format, from the
# textemoji ranges and the wide ranges in the emoji blocks.
    emojiranges=()
    for ((k=0; k<${#textemoji[@]}; k+=2)); do
        emojiranges+=("$(printf '%x-%x' "${textemoji[k]}" "${textemoji[k+1]}")")
    done
    for ((k=0; k<${#wide[@]}; k+=2)); do
        i=${wide[k]}
        InEmojiBlock && emojiranges+=("$(printf '%x-%x' "${wide[k]}" "${wide[k+1]}")")
    done
    list=${emojiranges[*]}
else
# Runs the fc-query command on the font file ("$fontfile") to extract the
# character ranges it supports, in hexadecimal, as start-end or single values.
    list=$(fc-query --format='%{charset}\n' "$fontfile")
fi

# First pass: computes the glyph text and display width of every code point.
# The widest code and the widest glyph give the width of every table cell.
# glyphs and widths are indexed by code point: bash lists the indexes of an
# array in increasing order, so the table is sorted even when the ranges are
# not.
glyphs=() widths=()
codewidth=4 glyphwidth=1
for range in $list; do
# Splits the range into start and end using the delimiter -.
# If there's no -, the range is a single code point, so end is set to start.
    IFS=- read -r start end <<<"$range"
    : "${end:=$start}"
    for ((i=16#$start; i<=16#$end; i++)); do
        printf -v char '\\U%x' "$i"
        printf -v char '%b' "$char"
        width=1
# Printable ASCII and private use areas (Nerd Font icons) need no check.
        if ((i >= 0x20 && i < 0x7F || i >= 0xE000 && i <= 0xF8FF || i >= 0xF0000)); then
            :
        elif InClass invisible; then
            char=$placeholder
        elif InClass combining; then
            char=$dottedcircle$char
        elif InClass textemoji; then
            if ((emoji)); then
                char=$char$vs16
                width=$emojiwidth
                ((width > glyphwidth)) && glyphwidth=$width
            fi
        elif InClass rtl; then
            char=$char$lrm
        elif InClass wide; then
# Only emoji get the variation selector, not CJK or fullwidth forms.
            ((emoji)) && InEmojiBlock && char=$char$vs16
            width=2
            glyphwidth=2
        fi
        glyphs[i]=$char widths[i]=$width
    done
done
codes=("${!glyphs[@]}")
((${#codes[@]})) || exit 0
printf -v last '%X' "${codes[-1]}"
((${#last} > codewidth)) && codewidth=${#last}

# Prints the cells of the array named $1, $2 cells per row, separated by |.
PrintCells() {
    local -n tablecells=$1
    local perrow=$2 k
    for k in "${!tablecells[@]}"; do
        ((k % perrow)) && printf ' | '
        printf '%s' "${tablecells[k]}"
        ((k % perrow == perrow - 1)) && printf '\n'
    done
    ((${#tablecells[@]} % perrow)) && printf '\n'
}

# Second pass: builds one cell per code point. Each cell is padded to the same
# display width, so every row is aligned.
cells=()
for i in "${codes[@]}"; do
    printf -v cell 'U+%0*X - %s%*s' "$codewidth" "$i" "${glyphs[i]}" "$((glyphwidth - widths[i]))" ''
    cells+=("$cell")
done

((allemoji)) || { PrintCells cells "$columns"; exit 0; }

echo 'Emoji'
PrintCells cells "$columns"

# Flags: two regional indicator letters (U+1F1E6 is A) give a country flag.
# The list holds the flags recommended by Unicode (RGI).
countries=(AC AD AE AF AG AI AL AM AO AQ AR AS AT AU AW AX AZ BA BB BD BE BF
    BG BH BI BJ BL BM BN BO BQ BR BS BT BV BW BY BZ CA CC CD CF CG CH CI CK
    CL CM CN CO CP CR CU CV CW CX CY CZ DE DG DJ DK DM DO DZ EA EC EE EG EH
    ER ES ET EU FI FJ FK FM FO FR GA GB GD GE GF GG GH GI GL GM GN GP GQ GR
    GS GT GU GW GY HK HM HN HR HT HU IC ID IE IL IM IN IO IQ IR IS IT JE JM
    JO JP KE KG KH KI KM KN KP KR KW KY KZ LA LB LC LI LK LR LS LT LU LV LY
    MA MC MD ME MF MG MH MK ML MM MN MO MP MQ MR MS MT MU MV MW MX MY MZ NA
    NC NE NF NG NI NL NO NP NR NU NZ OM PA PE PF PG PH PK PL PM PN PR PS PT
    PW PY QA RE RO RS RU RW SA SB SC SD SE SG SH SI SJ SK SL SM SN SO SR SS
    ST SV SX SY SZ TA TC TD TF TG TH TJ TK TL TM TN TO TR TT TV TW TZ UA UG
    UM UN US UY UZ VA VC VE VG VI VN VU WF WS XK YE YT ZA ZM ZW)
# Other flags: subdivision flags are a black flag followed by tag letters and
# CANCEL TAG; the last three are ZERO WIDTH JOINER sequences.
otherflags=(GB-ENG $'\U1f3f4\U000e0067\U000e0062\U000e0065\U000e006e\U000e0067\U000e007f'
    GB-SCT $'\U1f3f4\U000e0067\U000e0062\U000e0073\U000e0063\U000e0074\U000e007f'
    GB-WLS $'\U1f3f4\U000e0067\U000e0062\U000e0077\U000e006c\U000e0073\U000e007f'
    PRIDE $'\U1f3f3️‍\U1f308'
    TRANS $'\U1f3f3️‍⚧️'
    PIRATE $'\U1f3f4‍☠️')

flagslot=$((flagwidth > zwjwidth ? flagwidth : zwjwidth))
cells=()
for country in "${countries[@]}"; do
    printf -v first '%d' "'${country:0:1}"
    printf -v second '%d' "'${country:1:1}"
    printf -v flag '\\U%x\\U%x' "$((0x1F1E6 + first - 65))" "$((0x1F1E6 + second - 65))"
    printf -v cell '%-6s - %b%*s' "$country" "$flag" "$((flagslot - flagwidth))" ''
    cells+=("$cell")
done
for ((k=0; k<${#otherflags[@]}; k+=2)); do
    printf -v cell '%-6s - %s%*s' "${otherflags[k]}" "${otherflags[k+1]}" "$((flagslot - zwjwidth))" ''
    cells+=("$cell")
done
echo
echo 'Flags'
PrintCells cells "$columns"

# Skin tones: an emoji that accepts a skin tone (Emoji_Modifier_Base) is shown
# alone, then followed by each of the 5 modifiers U+1F3FB to U+1F3FF.
tonebases=(261D 261D 26F9 26F9 270A 270D 1F385 1F385 1F3C2 1F3C4 1F3C7 1F3C7
    1F3CA 1F3CC 1F442 1F443 1F446 1F450 1F466 1F478 1F47C 1F47C 1F481 1F483
    1F485 1F487 1F48F 1F48F 1F491 1F491 1F4AA 1F4AA 1F574 1F575 1F57A 1F57A
    1F590 1F590 1F595 1F596 1F645 1F647 1F64B 1F64F 1F6A3 1F6A3 1F6B4 1F6B6
    1F6C0 1F6C0 1F6CC 1F6CC 1F90C 1F90C 1F90F 1F90F 1F918 1F91F 1F926 1F926
    1F930 1F939 1F93C 1F93E 1F977 1F977 1F9B5 1F9B6 1F9B8 1F9B9 1F9BB 1F9BB
    1F9CD 1F9CF 1F9D1 1F9DD 1FAC3 1FAC5 1FAF0 1FAF8)
ToDecimal tonebases

baseslot=$((emojiwidth > 2 ? emojiwidth : 2))
cells=()
for ((k=0; k<${#tonebases[@]}; k+=2)); do
    for ((i=tonebases[k]; i<=tonebases[k+1]; i++)); do
        printf -v base '\\U%x' "$i"
        printf -v base '%b' "$base"
# A text emoji needs VARIATION SELECTOR-16 to show in color when alone.
        basewidth=2
        if InClass textemoji; then
            printf -v cell 'U+%05X - %s%*s' "$i" "$base$vs16" "$((baseslot - emojiwidth))" ''
        else
            printf -v cell 'U+%05X - %s%*s' "$i" "$base" "$((baseslot - basewidth))" ''
        fi
        for ((tone=0x1F3FB; tone<=0x1F3FF; tone++)); do
            printf -v modifier '\\U%x' "$tone"
            printf -v modifier '%b' "$modifier"
            cell+=" $base$modifier"
        done
        cells+=("$cell")
    done
done
echo
echo 'Skin tones'
# A skin tone cell holds 6 emoji, so it takes the room of about 3 other cells.
PrintCells cells "$(((columns + 2) / 3))"
exit 0
