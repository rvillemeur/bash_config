#!/usr/bin/env bash
# Installed into ~/.claude as a copy, not as a symlink: ~/.claude is shared with
# the Claude Code container, where this repo is mounted at ~/bash_config instead
# of ~/devzone/bash_config. A symlink to either path would dangle in the other
# context, so look for the real script under both roots.
for root in "${HOME}/bash_config" "${HOME}/devzone/bash_config"; do
    [ -f "${root}/claude/statusline-command.sh" ] && exec bash "${root}/claude/statusline-command.sh" "$@"
done
