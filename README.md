# tmux-text-object

Vim-like text-object yank functionality for tmux copy-mode-vi.

## Overview

This plugin brings Vim's text-object functionality to tmux's copy-mode-vi, allowing you to quickly yank words, WORDs, quoted text, and bracketed content using familiar Vim motions like `iw`, `yi"`, `ya(`, etc.

## Features

### Word/WORD Text Objects
- **iw (inner word)**: Yank a word (alphanumeric and underscore characters)
- **aw (around word)**: Yank a word plus surrounding whitespace
- **iW (inner WORD)**: Yank a WORD (non-whitespace characters)
- **aW (around WORD)**: Yank a WORD plus surrounding whitespace

### Quote Text Objects
- **i"** / **a"**: Yank inside/around double quotes
- **i'** / **a'**: Yank inside/around single quotes
- **i`** / **a`**: Yank inside/around backticks

### Bracket Text Objects
- **i(** / **a(** (or **i)** / **a)**): Yank inside/around parentheses
- **i[** / **a[** (or **i]** / **a]**): Yank inside/around square brackets
- **i{** / **a{** (or **i}** / **a}**): Yank inside/around curly braces
- **i<** / **a<** (or **i>** / **a>**): Yank inside/around angle brackets

### Paragraph Text Objects
- **ip (inner paragraph)**: Yank a paragraph (text block separated by blank lines)
- **ap (around paragraph)**: Yank a paragraph plus surrounding blank lines

### Additional Features
- Automatically exits copy-mode after yanking (just like Vim's `y` operator)
- Cross-platform clipboard support (pbcopy, clip.exe, xclip, wl-copy)
- Works in both normal mode (with text-objects) and visual mode (standard yank)
- No cursor movement - directly extracts text from the current line
- Copies to both tmux buffer and system clipboard simultaneously

## Installation

### Using TPM (Tmux Plugin Manager)

1. Add the plugin to your `~/.tmux.conf`:

```tmux
set -g @plugin 'nekowasabi/tmux-text-object'
```

2. Press `prefix + I` to fetch and install the plugin.

### Manual Installation

1. Clone this repository:

```bash
git clone https://github.com/nekowasabi/tmux-text-object.git ~/.tmux/plugins/tmux-text-object
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

   **Word/WORD Objects:**
   - `yiw`: Yank inner word
   - `yaw`: Yank around word (including surrounding space)
   - `yiW`: Yank inner WORD
   - `yaW`: Yank around WORD (including surrounding space)

   **Quote Objects:**
   - `yi"`: Yank inside double quotes
   - `ya"`: Yank around double quotes
   - `yi'`: Yank inside single quotes
   - `ya'`: Yank around single quotes
   - `` yi` ``: Yank inside backticks
   - `` ya` ``: Yank around backticks

   **Bracket Objects:**
   - `yi(` or `yi)`: Yank inside parentheses
   - `ya(` or `ya)`: Yank around parentheses
   - `yi[` or `yi]`: Yank inside square brackets
   - `ya[` or `ya]`: Yank around square brackets
   - `yi{` or `yi}`: Yank inside curly braces
   - `ya{` or `ya}`: Yank around curly braces
   - `yi<` or `yi>`: Yank inside angle brackets
   - `ya<` or `ya>`: Yank around angle brackets

   **Paragraph Objects:**
   - `yip`: Yank inner paragraph (text block without blank lines)
   - `yap`: Yank around paragraph (text block with surrounding blank lines)

### Examples

**Word Examples:**

Given the text: `hello_world test`

- Cursor on "hello_world" + `yiw` → yanks `hello_world`
- Cursor on "hello_world" + `yaw` → yanks `hello_world ` (with trailing space)

Given the text: `path/to/file.txt another`

- Cursor on "path/to/file.txt" + `yiW` → yanks `path/to/file.txt`
- Cursor on "path/to/file.txt" + `yaW` → yanks `path/to/file.txt ` (with trailing space)

**Quote Examples:**

Given the text: `echo "hello world" 'test'`

- Cursor on "hello" + `yi"` → yanks `hello world` (without quotes)
- Cursor on "hello" + `ya"` → yanks `"hello world"` (with quotes)
- Cursor on "test" + `yi'` → yanks `test`
- Cursor on "test" + `ya'` → yanks `'test'`

**Bracket Examples:**

Given the text: `func(arg1, arg2)`

- Cursor on "arg1" + `yi(` → yanks `arg1, arg2`
- Cursor on "arg1" + `ya(` → yanks `(arg1, arg2)`

Given the text: `array[0]`

- Cursor on "0" + `yi[` → yanks `0`
- Cursor on "0" + `ya[` → yanks `[0]`

Given the text: `{key: value}`

- Cursor on "key" + `yi{` → yanks `key: value`
- Cursor on "key" + `ya{` → yanks `{key: value}`

**Paragraph Examples:**

Given the text:
```
First paragraph line 1
First paragraph line 2

Second paragraph line 1
Second paragraph line 2
```

- Cursor on "First paragraph line 1" + `yip` → yanks:
  ```
  First paragraph line 1
  First paragraph line 2
  ```
  (without blank line)

- Cursor on "First paragraph line 1" + `yap` → yanks:
  ```
  First paragraph line 1
  First paragraph line 2

  ```
  (with blank line after)

## Text-Object Definitions

### Word vs WORD

- **word**: Consists of alphanumeric characters and underscores `[a-zA-Z0-9_]` (Vim's `iskeyword` equivalent)
- **WORD**: Consists of any non-whitespace characters

### Quote Text Objects

- **Quotes**: Double quotes `"`, single quotes `'`, and backticks `` ` ``
- **Inner (i)**: Selects text inside quotes (excludes quote characters)
- **Around (a)**: Selects text including quotes

### Bracket Text Objects

- **Brackets**: Parentheses `()`, square brackets `[]`, curly braces `{}`, angle brackets `<>`
- **Inner (i)**: Selects text inside brackets (excludes bracket characters)
- **Around (a)**: Selects text including brackets
- **Note**: Uses simple matching (finds nearest pair, does not handle nested brackets)

### Paragraph Text Objects

- **Paragraph**: A block of text separated by blank lines (lines that are empty or contain only whitespace)
- **Inner (ip)**: Selects the paragraph content only (excludes surrounding blank lines)
  - If cursor is on a blank line, no text is selected (consistent with Vim behavior)
- **Around (ap)**: Selects the paragraph plus one blank line before and/or after (if they exist)
- **Note**: This is the first multi-line text-object, supporting text that spans multiple lines

### Inner vs Around

- **inner (i)**: Selects only the text-object itself
- **around (a)**: Selects the text-object plus surrounding whitespace (for words) or delimiters (for quotes/brackets)
  - For words: Prefers trailing whitespace, falls back to leading whitespace if no trailing whitespace exists
  - For quotes/brackets: Includes the delimiter characters

## Clipboard Support

The plugin automatically detects and uses the appropriate clipboard tool with the following priority:

1. **WSL**: `clip.exe` (Windows Subsystem for Linux)
2. **macOS**: `pbcopy`
3. **Linux (X11)**: `xclip`
4. **Linux (Wayland)**: `wl-copy`

Text is always copied to tmux's buffer, and additionally copied to the system clipboard if a compatible tool is detected.

## How It Works

### Key Binding Architecture

The plugin uses a sophisticated three-tier key table system:

1. **Initial 'y' press**: The `yank-handler.sh` script detects if you're in visual or normal mode
   - **Visual mode** (`#{selection_present} == 1`): Performs standard yank operation
   - **Normal mode**: Switches to `text-object-yank` key table

2. **Text-object modifier**: After 'y' in normal mode
   - Pressing `i` switches to `text-object-inner` table (for inner text-objects)
   - Pressing `a` switches to `text-object-around` table (for around text-objects)

3. **Object specifier**: Final key determines the text-object type
   - `w`, `W` for words
   - `"`, `'`, `` ` `` for quotes
   - `(`, `)`, `[`, `]`, `{`, `}`, `<`, `>` for brackets
   - `p` for paragraphs

### Text Extraction

The implementation uses two different approaches depending on the text-object type:

**Single-line text-objects** (words, quotes, brackets):
- Uses tmux's `#{copy_cursor_line}` format variable to directly retrieve the text at the cursor position
- Preserves cursor position during the operation
- Eliminates visual artifacts from cursor movement
- Provides reliable text extraction even in complex scenarios

**Multi-line text-objects** (paragraphs):
- Uses tmux's `capture-pane -p` to retrieve all visible lines in the pane
- Scans up and down from the cursor position to find blank lines
- Extracts and joins multiple lines with preserved newlines
- Handles scroll position to correctly identify paragraph boundaries

### Smart Text Selection

- **Word boundaries**: Uses regex patterns (`[a-zA-Z0-9_]` for words, non-whitespace for WORDs)
- **Quote matching**: Simple left-then-right search algorithm for quote pairs
- **Bracket matching**: Searches for nearest bracket pair (opening or closing first)
- **Whitespace handling**: For 'around' objects, prefers trailing whitespace, falls back to leading

## Limitations

- **Single-line for most text-objects**: Word, quote, and bracket text-objects work within the current line only
  - **Exception**: Paragraph text-objects (ip/ap) support multi-line selection
- **Simple matching**: Quote and bracket matching uses a basic algorithm without nesting support
- **No escape handling**: Escaped quotes (like `\"`) are not treated specially
- **Cursor requirement**: Cursor must be positioned on/within the target text-object

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
