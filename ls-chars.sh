#!/bin/bash

# ./ls-chars.sh "Cascadia"

for range in $(fc-match --format='%{charset}\n' "$1"); do
    for n in $(seq "0x${range%-*}" "0x${range#*-}"); do
        printf "%04x\n" "$n"
    done
done  | while read -r n_hex; do
     count=$((count + 1))
     printf "%-5s\U$n_hex\t" "$n_hex"
     [ $((count % 10)) = 0 ] && printf "\n"
done
printf "\n"
