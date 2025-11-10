#!/usr/bin/env bash
# yank-handler.sh: Handle 'y' key press in copy-mode-vi
# Determines if we're in visual mode or normal mode and acts accordingly

set -u

# Get the directory where this script is located
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if we're in visual/selection mode by checking if there's a selection
# tmux provides #{selection_present} which is 1 if selection exists
selection_present=$(tmux display-message -p '#{selection_present}')

if [[ "$selection_present" == "1" ]]; then
    # We're in visual mode - perform normal yank operation
    # Get the selected text
    selected_text=$(tmux copy-mode -e 2>/dev/null || echo "")

    # Use copy-pipe-and-cancel to yank and exit
    # Detect clipboard tool (same logic as text-object-yank.sh)
    clipboard_cmd=""
    if command -v clip.exe >/dev/null 2>&1; then
        clipboard_cmd="clip.exe"
    elif command -v pbcopy >/dev/null 2>&1; then
        clipboard_cmd="pbcopy"
    elif command -v xclip >/dev/null 2>&1; then
        clipboard_cmd="xclip -selection clipboard"
    elif command -v wl-copy >/dev/null 2>&1; then
        clipboard_cmd="wl-copy"
    fi

    # Use tmux's built-in copy-pipe-and-cancel if we have a clipboard tool
    if [[ -n "$clipboard_cmd" ]]; then
        tmux send-keys -X copy-pipe-and-cancel "$clipboard_cmd"
    else
        # No clipboard tool, just use copy-selection-and-cancel
        tmux send-keys -X copy-selection-and-cancel
    fi
else
    # We're in normal mode - switch to text-object mode
    tmux switch-client -T text-object-yank
fi
