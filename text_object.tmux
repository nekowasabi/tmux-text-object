#!/usr/bin/env bash
# tmux-text-object: Vim-like text-object yank functionality for tmux copy-mode-vi
# Main plugin file for TPM (Tmux Plugin Manager)

# Get the directory where this script is located
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Set up key tables for text-object operations
# When 'y' is pressed in copy-mode-vi, run yank-handler to determine the context
# - If in visual mode: perform normal yank (copy selection and exit)
# - If in normal mode: switch to 'text-object-yank' table for text-objects
tmux bind-key -T copy-mode-vi y run-shell "$CURRENT_DIR/scripts/yank-handler.sh"

# When 'i' is pressed after 'y', switch to 'text-object-inner' table
tmux bind-key -T text-object-yank i switch-client -T text-object-inner

# When 'a' is pressed after 'y', switch to 'text-object-around' table
tmux bind-key -T text-object-yank a switch-client -T text-object-around

# When 'y' is pressed after 'y', yank the current line (yy behavior)
tmux bind-key -T text-object-yank y run-shell "$CURRENT_DIR/scripts/text-object-yank.sh yy"

# Define text-object bindings for inner text-objects
# yiw: yank inner word (word characters only)
tmux bind-key -T text-object-inner w run-shell "$CURRENT_DIR/scripts/text-object-yank.sh iw"

# yiW: yank inner WORD (non-whitespace characters)
tmux bind-key -T text-object-inner W run-shell "$CURRENT_DIR/scripts/text-object-yank.sh iW"

# Quote text-objects (inner)
tmux bind-key -T text-object-inner '"' run-shell "$CURRENT_DIR/scripts/text-object-yank.sh 'i\"'"
tmux bind-key -T text-object-inner "'" run-shell "$CURRENT_DIR/scripts/text-object-yank.sh \"i'\""
tmux bind-key -T text-object-inner '`' run-shell "$CURRENT_DIR/scripts/text-object-yank.sh 'i\`'"

# Bracket text-objects (inner)
tmux bind-key -T text-object-inner '(' run-shell "$CURRENT_DIR/scripts/text-object-yank.sh 'i('"
tmux bind-key -T text-object-inner ')' run-shell "$CURRENT_DIR/scripts/text-object-yank.sh 'i)'"
tmux bind-key -T text-object-inner '[' run-shell "$CURRENT_DIR/scripts/text-object-yank.sh 'i['"
tmux bind-key -T text-object-inner ']' run-shell "$CURRENT_DIR/scripts/text-object-yank.sh 'i]'"
tmux bind-key -T text-object-inner '{' run-shell "$CURRENT_DIR/scripts/text-object-yank.sh 'i{'"
tmux bind-key -T text-object-inner '}' run-shell "$CURRENT_DIR/scripts/text-object-yank.sh 'i}'"
tmux bind-key -T text-object-inner '<' run-shell "$CURRENT_DIR/scripts/text-object-yank.sh 'i<'"
tmux bind-key -T text-object-inner '>' run-shell "$CURRENT_DIR/scripts/text-object-yank.sh 'i>'"

# Paragraph text-object (inner)
tmux bind-key -T text-object-inner 'p' run-shell "$CURRENT_DIR/scripts/text-object-yank.sh 'ip'"

# Define text-object bindings for around text-objects
# yaw: yank around word (word + surrounding whitespace)
tmux bind-key -T text-object-around w run-shell "$CURRENT_DIR/scripts/text-object-yank.sh aw"

# yaW: yank around WORD (WORD + surrounding whitespace)
tmux bind-key -T text-object-around W run-shell "$CURRENT_DIR/scripts/text-object-yank.sh aW"

# Quote text-objects (around)
tmux bind-key -T text-object-around '"' run-shell "$CURRENT_DIR/scripts/text-object-yank.sh 'a\"'"
tmux bind-key -T text-object-around "'" run-shell "$CURRENT_DIR/scripts/text-object-yank.sh \"a'\""
tmux bind-key -T text-object-around '`' run-shell "$CURRENT_DIR/scripts/text-object-yank.sh 'a\`'"

# Bracket text-objects (around)
tmux bind-key -T text-object-around '(' run-shell "$CURRENT_DIR/scripts/text-object-yank.sh 'a('"
tmux bind-key -T text-object-around ')' run-shell "$CURRENT_DIR/scripts/text-object-yank.sh 'a)'"
tmux bind-key -T text-object-around '[' run-shell "$CURRENT_DIR/scripts/text-object-yank.sh 'a['"
tmux bind-key -T text-object-around ']' run-shell "$CURRENT_DIR/scripts/text-object-yank.sh 'a]'"
tmux bind-key -T text-object-around '{' run-shell "$CURRENT_DIR/scripts/text-object-yank.sh 'a{'"
tmux bind-key -T text-object-around '}' run-shell "$CURRENT_DIR/scripts/text-object-yank.sh 'a}'"
tmux bind-key -T text-object-around '<' run-shell "$CURRENT_DIR/scripts/text-object-yank.sh 'a<'"
tmux bind-key -T text-object-around '>' run-shell "$CURRENT_DIR/scripts/text-object-yank.sh 'a>'"

# Paragraph text-object (around)
tmux bind-key -T text-object-around 'p' run-shell "$CURRENT_DIR/scripts/text-object-yank.sh 'ap'"
