# Terminal configuration

Bash, tmux, git, screen and Claude Code configuration for a Fedora workstation,
themed on the neovim **tokyonight-moon** palette.

## Install

```sh
git clone --recurse-submodules <this repo> ~/devzone/bash_config
cd ~/devzone/bash_config
./install.sh --dry-run    # print what it would do
./install.sh              # do it
```

`install.sh` is safe to re-run. It leaves correct links alone, replaces a stale
link that already points into this checkout, and backs up anything else in the
way as `<target>.bak.<timestamp>`. It also runs `git submodule update --init`
when `vendor/powerline.bash` is missing.

What it puts in `$HOME`:

| Link | Target |
| --- | --- |
| `~/.bashrc` | `bash/bashrc` |
| `~/.bash_profile` | `bash/bash_profile` |
| `~/.bash_logout` | `bash/bash_logout` |
| `~/.bash_aliases` | `bash/bash_aliases` |
| `~/.gitconfig` | `git/gitconfig` |
| `~/.tmux.conf` | `tmux/tmux.conf` |
| `~/.screenrc` | `screen/screenrc` |

Plus two **copies** (not links) in `~/.claude`, from `claude/launchers/`. See
[Claude Code](#claude-code) below.

## Layout

```
bash/      bashrc, bash_profile, bash_logout, bash_aliases
tmux/      tmux.conf and the scripts its status bar calls
claude/    Claude Code status line, launchers, reference settings.json
git/       gitconfig
screen/    screenrc
fonts/     Nerd Font install notes and glyph-listing scripts
tools/     colour and palette demo scripts
windows/   Windows terminal registry files
vendor/    submodules: powerline.bash, icons-in-terminal, choose
install.sh
```

`bash/bashrc` resolves the repo root from the `~/.bashrc` symlink into
`$DOTFILES`, so the checkout can live anywhere.

## Requirements

- **tmux 3.x** (developed against 3.7c) with [tpm] in `~/.tmux/plugins/tpm`.
  Press `prefix I` on first run to fetch the plugins listed at the bottom of
  `tmux/tmux.conf`.
- A **Nerd Font**: `CaskaydiaMono Nerd Font Mono`. See
  `fonts/install_Caskaidia_font.md`. Without it the status bar glyphs show as
  boxes.
- `icons-in-terminal` for the bash prompt icons: run
  `vendor/icons-in-terminal/install.sh` once.

[tpm]: https://github.com/tmux-plugins/tpm

## tmux status bar

Every segment is a rounded pill (`` U+E0B6 / `` U+E0B4) carrying its own caps
and trailing space, so a segment with nothing to say disappears without leaving
a broken colour chain behind.

- **left** — window list, one pill per window
- **centre** — Claude Code usage, from `tmux/tmux-claude-status.sh`
- **right** — battery (only while discharging), mode indicator, pomodoro (only
  while a timer runs), clock

`tokyo-night-tmux` is deliberately **not** enabled: it rewrites `status-left`,
`status-right` and the window formats at load time, which wipes the mode
indicator, the pomodoro timer and the clock. Its look is reproduced natively
instead.

Three tmux quirks cost real debugging time here and are documented at the top of
the status section of `tmux/tmux.conf`:

1. `#{?cond,a,b}` splits on its first unescaped comma, so inside a conditional
   write one `#[]` directive per attribute, never `#[fg=x,bg=y]`.
2. An `#[align=...]` block has its outer ASCII whitespace trimmed; pad with a
   non-breaking space (U+00A0).
3. `window-status-separator` is inert once `status-format[0]` is overridden, so
   each window format carries its own padding.

## Claude Code

`claude/statusline-command.sh` renders the Claude Code status line: left group
for distro, path, git branch and model, right group for context and the 5h / 7d
rate-limit meters. It also writes
`${XDG_CACHE_HOME:-$HOME/.cache}/claude-code/usage.env`, which
`tmux/tmux-claude-status.sh` reads to draw the same meters in the tmux status
bar, recomputing the countdowns live.

The two scripts in `~/.claude` are copies, not symlinks, because `~/.claude` is
shared with the Claude Code container, where this repo is mounted at
`~/bash_config` instead of `~/devzone/bash_config`; a symlink to either path
dangles in the other context. The installed copies are the launchers from
`claude/launchers/`, which look under both roots and `exec` the real script, so
editing the real script needs no reinstall.

`install.sh` never writes `~/.claude/settings.json`, which holds live state
(model, plugins, env). `claude/settings.json` is the reference copy of the keys
that matter here; the installer only reports when the `statusLine` hookup is
absent.
