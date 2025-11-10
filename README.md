# tmux-text-object

Vim-like text-object yank functionality for tmux copy-mode-vi.

## Overview

This plugin brings Vim's text-object functionality to tmux's copy-mode-vi, allowing you to quickly yank words and WORDs using familiar Vim motions like `iw`, `aw`, `iW`, and `aW`.

## Features

- **iw (inner word)**: Yank a word (alphanumeric and underscore characters)
- **aw (around word)**: Yank a word plus surrounding whitespace
- **iW (inner WORD)**: Yank a WORD (non-whitespace characters)
- **aW (around WORD)**: Yank a WORD plus surrounding whitespace
- Automatically exits copy-mode after yanking (just like Vim's `y` operator)
- Cross-platform clipboard support (pbcopy, clip.exe, xclip, wl-copy)

## Installation

### Using TPM (Tmux Plugin Manager)

1. Add the plugin to your `~/.tmux.conf`:

```tmux
set -g @plugin 'yourusername/tmux-text-object'
```

2. Press `prefix + I` to fetch and install the plugin.

### Manual Installation

1. Clone this repository:

```bash
git clone https://github.com/yourusername/tmux-text-object.git ~/.tmux/plugins/tmux-text-object
```

2. Add to your `~/.tmux.conf`:

```tmux
run-shell ~/.tmux/plugins/tmux-text-object/text_object.tmux
```

3. Reload tmux configuration:

```bash
tmux source-file ~/.tmux.conf
```

### Local Development

For local development, you can load the plugin directly:

```tmux
run-shell ~/repos/tmux-text-object/text_object.tmux
```

## Usage

1. Enter copy-mode: `prefix + [`
2. Navigate to a word using standard Vi navigation keys
3. Use text-object commands (Vim-style):
   - `yiw`: Yank inner word
   - `yaw`: Yank around word (including surrounding space)
   - `yiW`: Yank inner WORD
   - `yaW`: Yank around WORD (including surrounding space)

### Examples

Given the text: `hello_world test`

- Cursor on "hello_world" + `yiw` → yanks "hello_world"
- Cursor on "hello_world" + `yaw` → yanks "hello_world " (with trailing space)

Given the text: `path/to/file.txt another`

- Cursor on "path/to/file.txt" + `yiW` → yanks "path/to/file.txt"
- Cursor on "path/to/file.txt" + `yaW` → yanks "path/to/file.txt " (with trailing space)

## Text-Object Definitions

### Word vs WORD

- **word**: Consists of alphanumeric characters and underscores `[a-zA-Z0-9_]` (Vim's `iskeyword` equivalent)
- **WORD**: Consists of any non-whitespace characters

### Inner vs Around

- **inner (i)**: Selects only the text-object itself
- **around (a)**: Selects the text-object plus surrounding whitespace
  - Prefers trailing whitespace
  - Falls back to leading whitespace if no trailing whitespace exists

## Clipboard Support

The plugin automatically detects and uses the appropriate clipboard tool with the following priority:

1. **WSL**: `clip.exe` (Windows Subsystem for Linux)
2. **macOS**: `pbcopy`
3. **Linux (X11)**: `xclip`
4. **Linux (Wayland)**: `wl-copy`

Text is always copied to tmux's buffer, and additionally copied to the system clipboard if a compatible tool is detected.

## Requirements

- tmux 2.4+
- bash
- copy-mode-vi enabled (`set-window-option -g mode-keys vi`)

## Testing

Run the test suite:

```bash
./tests/test-runner.sh
```

## Troubleshooting

### Clipboard not working

Make sure you have a clipboard tool installed:

- **macOS**: pbcopy (pre-installed)
- **WSL**: Available by default
- **Linux**: Install `xclip` or `wl-clipboard`

### Key bindings not working

1. Verify tmux is using vi mode:
   ```bash
   tmux show-window-options -g mode-keys
   ```
   Should output: `mode-keys vi`

2. Check if the plugin is loaded:
   ```bash
   tmux source-file ~/.tmux.conf
   ```

3. Restart tmux:
   ```bash
   tmux kill-server
   tmux
   ```

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## License

MIT License - see LICENSE file for details

## Author

Created for enhancing tmux productivity with Vim-like text-objects.

## Acknowledgments

- Inspired by Vim's text-object functionality
- Built for TPM (Tmux Plugin Manager) compatibility
