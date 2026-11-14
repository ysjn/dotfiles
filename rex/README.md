# Rex copy mode

`init.lua` loads [CJNE/rex-copy-mode](https://github.com/CJNE/rex-copy-mode) from
`~/.local/share/rex/plugins/rex-copy-mode`. The installed upstream revision is
recorded in that directory's `UPSTREAM` file.

`Ctrl+Shift+L` opens the viewer, or passes through to Codex's `select_transcript`
when Codex is the foreground process.

The plugin's `nvim` option points to `copy-mode-nvim` in this repository. This
wrapper removes the plugin's `-u NONE`, so Neovim loads the usual user config,
then adds viewer-local `q` / `Esc` mappings after the plugin's startup commands.
Both keys close the viewer without copying, including while selecting text.
`y` and visual-mode `Enter` retain the plugin's copy behavior.

The viewer still overrides display options needed for scrollback, such as
hiding the status line. The plugin's `-i NONE` and `-n` remain in place to
disable ShaDa and swap files in this disposable viewer.

The plugin's runtime files remain unmodified. Updating those files preserves
the custom keys; keep the `nvim` option pointing to this executable wrapper.
The wrapper uses `/opt/homebrew/bin/nvim`, matching this Mac's installation.

After changing `init.lua`, run `rex config check` and `rex config reload`.
Wrapper changes apply to newly opened viewers. An already open viewer keeps
its existing mappings until it closes.
