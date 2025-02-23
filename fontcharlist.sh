#!/bin/bash -

# ./fontcharlist.sh /usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf
# bash fontcharlist.sh ~/.local/share/fonts/CaskaydiaCove/CaskaydiaMonoNerdFontMono-Regular.ttf | more

Usage() { echo "$0 FontFile"; exit 1; }
SayError() { local error=$1; shift; echo "$0: $@"; exit "$error"; }

[ "$#" -ne 1 ] && Usage

width=90
fontfile="$1"

[ -f "$fontfile" ] || SayError 4 'File not found'

# Runs the fc-query command on the font file ("$fontfile") to extract the
# character ranges it supports. The --format='%{charset}\n' option specifies
# that fc-query should return character ranges in hexadecimal format, separated
# by newlines.
list=$(fc-query --format='%{charset}\n' "$fontfile")

# Iterates through each range in the list.
for range in $list; do
# Splits the range into start and end using the delimiter -.
# If there’s no -, only start is assigned.
    IFS=- read start end <<<"$range"
    if [ "$end" ]; then
# If there's an $end value, Convert start and end from hexadecimal to decimal 
# using $((16#$value))
        start=$((16#$start))
        end=$((16#$end))
        for((i=start;i<=end;i++)); do
# Generate a Unicode character escape sequence in the form \Uxxxxx and assig
# it to the variable char
            printf -v char '\\U%x' "$i"
            printf '|\\U%5s - %1b' "$i" "$char"
        done
    else
# Simply print the single character represented by start
        printf '%b' "\\U$start"
    fi
# Pipes the output to grep -oP '.{'"$width"'}'. This ensures that the output is
# displayed in chunks of $width characters (default: 90). It uses Perl-compatible
# regular expressions (-oP) to match chunks of exactly $width characters.
done | grep -oP '.{'"$width"'}'
