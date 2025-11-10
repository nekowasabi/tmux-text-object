#!/usr/bin/env bash
# tmux-text-object: Vim-like text-object yank functionality for tmux copy-mode-vi
# Main plugin file for TPM (Tmux Plugin Manager)

# Get the directory where this script is located
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Set up key tables for text-object operations
# When 'i' is pressed in copy-mode-vi, switch to 'text-object-inner' table
tmux bind-key -T copy-mode-vi i switch-client -T text-object-inner

# When 'a' is pressed in copy-mode-vi, switch to 'text-object-around' table
tmux bind-key -T copy-mode-vi a switch-client -T text-object-around

# Define text-object bindings for inner text-objects
# iw: inner word (word characters only)
tmux bind-key -T text-object-inner w run-shell "$CURRENT_DIR/scripts/text-object-yank.sh iw"

# iW: inner WORD (non-whitespace characters)
tmux bind-key -T text-object-inner W run-shell "$CURRENT_DIR/scripts/text-object-yank.sh iW"

# Define text-object bindings for around text-objects
# aw: around word (word + surrounding whitespace)
tmux bind-key -T text-object-around w run-shell "$CURRENT_DIR/scripts/text-object-yank.sh aw"

# aW: around WORD (WORD + surrounding whitespace)
tmux bind-key -T text-object-around W run-shell "$CURRENT_DIR/scripts/text-object-yank.sh aW"
