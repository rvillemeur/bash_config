#!/bin/bash

# ./ls-chars.sh "Cascadia"

# Loops through each character range output by fc-match.
# The fc-match command queries the font file ($1, the first argument to the
# script) and outputs the character ranges it supports in the format start-end.
for range in $(fc-match --format='%{charset}\n' "$1"); do
# Iterates over each number in the sequence.
#  - range%-* :
#    Extracts the starting value by removing everything after (and including) the -
#  - range#*- :
#    Extracts the ending value by removing everything before (and including) the -.
#  - seq "0x${range%-*}" "0x${range#*-}":
#    Generates a sequence of numbers between the start and end values (in hexadecimal format).
Generates a sequence of numbers between the start and end values (in hexadecimal format).
    for n in $(seq "0x${range%-*}" "0x${range#*-}"); do
        printf "%04x\n" "$n"
    done
done  | while read -r n_hex; do
     count=$((count + 1))
# Prints the hexadecimal value ($n_hex) and its corresponding Unicode character
# using the \U escape sequence. The %-5s ensures the hexadecimal value is
# left-aligned in a field of width 5, followed by the Unicode character.
     printf "%-5s\U$n_hex\t" "$n_hex"
# Checks if count is a multiple of 10. If true, it prints a newline to format 
# the output into rows of 10 characters.
     [ $((count % 10)) = 0 ] && printf "\n"
done
printf "\n"
