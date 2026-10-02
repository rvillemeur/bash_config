#!/usr/bin/env bash
# Installed into ~/.claude as a copy, not as a symlink: see the comment in
# statusline-command.sh next to this file. tmux.conf calls this by the fixed
# path ~/.claude/tmux-claude-status.sh.
for root in "${HOME}/bash_config" "${HOME}/devzone/bash_config"; do
    [ -f "${root}/tmux/tmux-claude-status.sh" ] && exec bash "${root}/tmux/tmux-claude-status.sh" "$@"
done
