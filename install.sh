#!/usr/bin/env bash
# Link this checkout into $HOME. Safe to re-run: existing correct links are left
# alone, and anything else in the way is moved to <target>.bak.<timestamp>
# before being replaced.
#
#   ./install.sh            do it
#   ./install.sh --dry-run  print what it would do and change nothing
set -u

REPO="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
DRY_RUN=0
[ "${1-}" = "--dry-run" ] && DRY_RUN=1
STAMP="$(date +%Y%m%d%H%M%S)"

# symlinks: "<path relative to the repo>:<path relative to $HOME>"
LINKS="
bash/bashrc:.bashrc
bash/bash_profile:.bash_profile
bash/bash_logout:.bash_logout
bash/bash_aliases:.bash_aliases
git/gitconfig:.gitconfig
tmux/tmux.conf:.tmux.conf
screen/screenrc:.screenrc
"

# copies into ~/.claude, which is shared with the Claude Code container: a
# symlink to this checkout would dangle there, so these are small launchers
# that look for the real script under both mount points.
COPIES="
claude/launchers/statusline-command.sh:.claude/statusline-command.sh
claude/launchers/tmux-claude-status.sh:.claude/tmux-claude-status.sh
"

say() { printf '%s\n' "$*"; }
run() {
    if [ "$DRY_RUN" -eq 1 ]; then
        say "  would: $*"
    else
        "$@"
    fi
}

backup() {
    local target=$1
    [ -e "$target" ] || [ -L "$target" ] || return 0
    # A symlink that already points inside this checkout is one of ours, stale
    # only because a file moved. Replace it, do not keep a .bak of a dead link.
    if [ -L "$target" ]; then
        case "$(readlink -f "$target")" in
            "$REPO"/*)
                say "  replace stale link $target"
                run rm -f -- "$target"
                return 0
                ;;
        esac
    fi
    say "  backup $target -> $target.bak.$STAMP"
    run mv -- "$target" "$target.bak.$STAMP"
}

link_one() {
    local src="$REPO/$1" target="$HOME/$2"
    if [ ! -e "$src" ]; then
        say "MISSING $1 -- skipped"
        return 1
    fi
    if [ -L "$target" ] && [ "$(readlink -f "$target")" = "$(readlink -f "$src")" ]; then
        say "ok      ~/$2"
        return 0
    fi
    backup "$target"
    say "link    ~/$2 -> $1"
    run mkdir -p -- "$(dirname "$target")"
    run ln -s -- "$src" "$target"
}

copy_one() {
    local src="$REPO/$1" target="$HOME/$2"
    if [ ! -e "$src" ]; then
        say "MISSING $1 -- skipped"
        return 1
    fi
    if [ -f "$target" ] && [ ! -L "$target" ] && cmp -s "$src" "$target"; then
        say "ok      ~/$2"
        return 0
    fi
    backup "$target"
    say "copy    ~/$2 <- $1"
    run mkdir -p -- "$(dirname "$target")"
    run cp -- "$src" "$target"
    run chmod +x -- "$target"
}

say "repo: $REPO"
[ "$DRY_RUN" -eq 1 ] && say "(dry run)"

say "symlinks:"
printf '%s\n' "$LINKS" | while IFS=: read -r src target; do
    [ -n "${src:-}" ] || continue
    link_one "$src" "$target"
done

say "~/.claude launchers:"
printf '%s\n' "$COPIES" | while IFS=: read -r src target; do
    [ -n "${src:-}" ] || continue
    copy_one "$src" "$target"
done

# Vendored prompt and icons live in submodules; bash/bashrc sources
# vendor/powerline.bash/powerline.bash and fails loudly without them.
if [ ! -f "$REPO/vendor/powerline.bash/powerline.bash" ]; then
    say "submodules: missing, fetching"
    run git -C "$REPO" submodule update --init --recursive
else
    say "submodules: present"
fi

# ~/.claude/settings.json is live Claude Code state (model, plugins, env), so it
# is never overwritten. claude/settings.json keeps the reference copy of the
# keys that matter here; report only when the status line hookup disagrees.
NEED='bash ~/.claude/statusline-command.sh'
if [ -f "$HOME/.claude/settings.json" ] && ! grep -qF "$NEED" "$HOME/.claude/settings.json"; then
    say "note: ~/.claude/settings.json has no statusLine command \"$NEED\""
    say "      add it by hand, or copy the block from claude/settings.json"
fi

say "done"
