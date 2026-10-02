#!/bin/bash
for i in {0..255} ; do
# \x1b[38;5;${i}m: # This is an ANSI escape sequence to set the text color to color i.
# - \x1b: Escape character (ESC).
# - [38;5;${i}m:
#   - 38 sets the foreground color.
#   - 5 specifies that we are using the 256-color mode.
#   - ${i} is the color index (from 0 to 255).
#
# %3d: # This is a format specifier that prints the number i (color index) 
# right-aligned in a field of width 3.
    printf "\x1b[38;5;${i}m%3d " "${i}"
# A newline is added after color 15. Colors 0–15 are the standard colors (e.g., black, red, green, etc.).
# After color 15, the script organizes the colors into rows of 12 colors each.
    if (( $i == 15 )) || (( $i > 15 )) && (( ($i-15) % 12 == 0 )); then
        echo;
    fi
done
