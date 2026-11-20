# Rex configuration

This directory manages custom Rex settings, supporting scripts, and tests.

| File | Responsibility |
| --- | --- |
| `init.lua` | Loads the configuration files in order. |
| `actions.lua` | Custom actions, including session closure and attention jumps. |
| `plugins.lua` | Plugin initialization, options, and plugin-specific behavior. |
| `keybindings.lua` | All keyboard shortcuts and key modes, including plugin shortcuts. |

`init.lua` reads the other files from `~/dev/dotfiles/rex`, so the existing
`~/.config/rex/init.lua` symlink needs no change. Files use `dofile` so each
reload reads their latest contents.

After changing any Lua configuration file, run `rex config check` and
`rex config reload`.

## Codex line scrolling

When Codex is the local foreground process, `Ctrl+B` sends three `PageUp` keys
and `Ctrl+F` sends three `PageDown` keys. With the Codex configuration below,
each shortcut scrolls three lines in the fullscreen conversation without
entering selection mode and replaces those keys' input-cursor movement in Codex.
Other programs receive the original keys, including Codex reached through SSH.
The handler writes the page-key escape sequences directly to the source pane;
Rex does not allow `rex.client.queue` inside a key handler.

Add this section to `~/.codex/config.toml`, then restart Codex:

```toml
[tui.keymap.pager]
scroll_up = ["up", "k", "page-up"]
scroll_down = ["down", "j", "page-down"]
page_up = ["shift-space", "ctrl-b"]
page_down = ["space", "ctrl-f"]
```

This also makes physical `PageUp` / `PageDown` (`Fn+Up` / `Fn+Down` on macOS)
scroll one line. The page bindings above retain the other pager shortcuts
without conflicting with the line bindings.

Codex 0.170.0 only accepts `PageUp` / `PageDown` as configurable scroll keys in
the main conversation view; custom `Ctrl+B` / `Ctrl+F` bindings do not reach it.
The TODO in `keybindings.lua` tracks moving these bindings into Codex once it
supports that configuration.

Run `luajit rex/tests/codex-page-scroll.lua` to check routing and error handling.

## Copy mode

`plugins.lua` loads [CJNE/rex-copy-mode](https://github.com/CJNE/rex-copy-mode) from
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

Copy-mode viewers skip Lazy's automatic plugin update checks at startup.
They still load the usual Neovim config and plugins. Regular Neovim sessions
continue to check for updates.

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

`Ctrl+K`, then `x` closes the focused pane and its running process without a
confirmation when other panes remain in the session.
For the last pane in the session, including other tabs and detached panes,
it asks before closing the session and its running process. The macOS dialog
defaults to Close (Enter), supports Cancel (Esc), and cancels after 20 seconds.
If the pane layout changes while the dialog is open, nothing is closed.

Run `luajit rex/tests/close-pane-or-session.lua` to check this behavior.

## Rexflash

`Ctrl+K`, then `f` labels targets; `Ctrl+K`, then `/` searches text.
In both modes, an unmodified hint opens, Ctrl pastes into the source pane,
and Shift copies. Rexflash copies every selection before running its action,
including Open and Paste.

`rexflash` starts `~/dev/rexflash/target/release/rexflash` directly, without
loading Node or nvm before hints appear. Only Open launches `rexflash.ts` with
Node 22.18 or newer. Open uses Node on PATH, falling back to the existing nvm
default when Rex starts with a short PATH. The upstream Lua extension is unchanged.

The local Rust checkout captures the source pane while compiling patterns and
fetching its size. Rebuild it with `cargo build --release --manifest-path
"$HOME/dev/rexflash/Cargo.toml"` after changing that checkout.

Open resolves paths against the source pane's working directory. Recognized
source/config extensions, known names such as Makefile, and code MIME types open
in Neovim in a new pane immediately to the left of the source pane. MIME checks
exclude binary files, even with a source extension. Ordinary text/Markdown,
directories, PDFs, images other than SVG, and URLs use macOS Open. Extensionless
`text/plain` files also use macOS Open unless their name is recognized.

`path:line[:column]`, `path#Lline[Ccolumn]`, and local `file://` links with those
locations preserve the position in Neovim. The editor gets focus after Rexflash
exits. Ctrl/Shift selections and cancellation retain the source pane's focus.
Shell text is passed as arguments, never evaluated as a command.

Run `node --test rex/tests/rexflash.test.ts` and
`luajit rex/tests/copy-mode-routing.lua` to check the wrapper and bindings.

Startup measurements on this Mac (2026-11-20), from the hint action request to
the hint appearing in a VT capture:

| Change | Samples | Median | p90 |
| --- | ---: | ---: | ---: |
| Original launcher | 10 | 588 ms | 592 ms |
| Start Rust without Node/nvm | 10 | 174 ms | 184 ms |
| Also overlap capture with size/pattern setup | 30 | 146 ms | 156 ms |

The final version measured 152 ms median / 174 ms p90 with 5,000 lines containing
Japanese text, paths, URLs, and OSC 8 links. Generating initial hints only for the
visible rows and adding a second worker for size lookup each saved less than
4 ms in comparisons; neither produced a stable gain, so both were discarded.
The measurements include CLI startup and polling, but exclude physical key
handling and display rendering. Before/after VT frames matched for hint, flash,
and scrolling. A mutual-barrier check verified concurrent size/capture calls;
an error check verified failed size lookup still reports an error without hanging.
