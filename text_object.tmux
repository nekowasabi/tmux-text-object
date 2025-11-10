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

# Define text-object bindings for inner text-objects
# yiw: yank inner word (word characters only)
tmux bind-key -T text-object-inner w run-shell "$CURRENT_DIR/scripts/text-object-yank.sh iw"

# yiW: yank inner WORD (non-whitespace characters)
tmux bind-key -T text-object-inner W run-shell "$CURRENT_DIR/scripts/text-object-yank.sh iW"

# Define text-object bindings for around text-objects
# yaw: yank around word (word + surrounding whitespace)
tmux bind-key -T text-object-around w run-shell "$CURRENT_DIR/scripts/text-object-yank.sh aw"

# yaW: yank around WORD (WORD + surrounding whitespace)
tmux bind-key -T text-object-around W run-shell "$CURRENT_DIR/scripts/text-object-yank.sh aW"
