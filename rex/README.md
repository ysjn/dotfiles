# Rex configuration

This directory manages custom Rex settings and shortcuts in `init.lua`,
along with supporting scripts and tests.

After changing `init.lua`, run `rex config check` and `rex config reload`.

## Copy mode

`init.lua` loads [CJNE/rex-copy-mode](https://github.com/CJNE/rex-copy-mode) from
`~/.local/share/rex/plugins/rex-copy-mode`. The installed upstream revision is
recorded in that directory's `UPSTREAM` file.

`Ctrl+Shift+L` opens the viewer, or passes through to Codex's `select_transcript`
when Codex is the foreground process.

The plugin's `nvim` option points to `copy-mode-nvim` in this repository. This
wrapper removes the plugin's `-u NONE`, so Neovim loads the usual user config,
then adds a viewer-local `q` mapping after the plugin's startup commands.
`q` closes the viewer without copying, including while selecting text.
`Esc` retains its normal selection and terminal-mode cancellation behavior.
`y` and visual-mode `Enter` retain the plugin's copy behavior.

The viewer still overrides display options needed for scrollback, such as
hiding the status line. The plugin's `-i NONE` and `-n` remain in place to
disable ShaDa and swap files in this disposable viewer.

The plugin's runtime files remain unmodified. Updating those files preserves
the custom keys; keep the `nvim` option pointing to this executable wrapper.
The wrapper uses `/opt/homebrew/bin/nvim`, matching this Mac's installation.

Wrapper changes apply to newly opened viewers. An already open viewer keeps
its existing mappings until it closes.

## Jump to an agent needing attention

`Ctrl+K`, then `k` uses Rex's built-in program status API to jump directly to
another pane across sessions and tabs. Approval or question waits (`blocked`)
come first, followed by completed or failed work (`done` / `error`). Within
each priority, the most recently reported status wins. The current pane,
detached panes, and `idle` / `working` statuses are skipped. With no candidate,
focus stays where it is.

This needs no additional plugin. It depends on programs reporting OSC 7501
status; programs without status reports are not included.

Run `luajit rex/tests/attention-jump.lua` to check selection and error handling.

## Closing panes and sessions

`Ctrl+K`, then `x` closes the focused pane using Rex's normal close action.
For the last pane in the session, including other tabs and detached panes,
it asks before closing the session and its running process. The macOS dialog
defaults to Close (Enter), supports Cancel (Esc), and cancels after 20 seconds.
If the pane layout changes while the dialog is open, nothing is closed.

Run `luajit rex/tests/close-pane-or-session.lua` to check this behavior.
