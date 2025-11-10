#!/usr/bin/env bash
# text-object-yank.sh: Yank text-objects in tmux copy-mode-vi
# Usage: text-object-yank.sh <text-object-type>
# text-object-type: iw, aw, iW, aW

set -u

# Debug log file
DEBUG_LOG="/tmp/tmux-text-object-debug.log"

# Text-object type (iw, aw, iW, aW)
TEXT_OBJECT="${1:-}"

# Calculate word range based on text-object type
# Arguments: line, cursor_x, text_object_type
# Returns: "start end" (inclusive range)
calculate_word_range() {
    local line="$1"
    local cursor_x="$2"
    local text_object="$3"
    local line_length="${#line}"

    # If cursor is beyond line length, return empty
    if [[ $cursor_x -ge $line_length ]]; then
        echo ""
        return
    fi

    local start=$cursor_x
    local end=$cursor_x

    case "$text_object" in
        iw)
            # inner word: [a-zA-Z0-9_]
            # Check if cursor is on a word character
            local char="${line:$cursor_x:1}"
            if [[ ! "$char" =~ [a-zA-Z0-9_] ]]; then
                # Not on a word character, return empty
                echo ""
                return
            fi

            # Find start of word
            while [[ $start -gt 0 ]]; do
                local char="${line:$((start-1)):1}"
                if [[ "$char" =~ [a-zA-Z0-9_] ]]; then
                    ((start--))
                else
                    break
                fi
            done

            # Find end of word
            while [[ $end -lt $line_length ]]; do
                local char="${line:$end:1}"
                if [[ "$char" =~ [a-zA-Z0-9_] ]]; then
                    ((end++))
                else
                    break
                fi
            done

            # Convert end from exclusive to inclusive
            ((end--))
            ;;

        iW)
            # inner WORD: non-whitespace
            # Check if cursor is on a non-whitespace character
            local char="${line:$cursor_x:1}"
            if [[ "$char" == " " || "$char" == $'\t' ]]; then
                # On whitespace, return empty
                echo ""
                return
            fi

            # Find start of WORD
            while [[ $start -gt 0 ]]; do
                local char="${line:$((start-1)):1}"
                if [[ "$char" != " " && "$char" != $'\t' ]]; then
                    ((start--))
                else
                    break
                fi
            done

            # Find end of WORD
            while [[ $end -lt $line_length ]]; do
                local char="${line:$end:1}"
                if [[ "$char" != " " && "$char" != $'\t' ]]; then
                    ((end++))
                else
                    break
                fi
            done

            # Convert end from exclusive to inclusive
            ((end--))
            ;;

        aw)
            # around word: word + trailing space (or leading space if no trailing)
            # First calculate inner word range
            local iw_range
            iw_range=$(calculate_word_range "$line" "$cursor_x" "iw")
            read -r start end <<< "$iw_range"

            # Try to include trailing space (end+1 position)
            local next_pos=$((end + 1))
            if [[ $next_pos -lt $line_length ]]; then
                local char="${line:$next_pos:1}"
                if [[ "$char" == " " || "$char" == $'\t' ]]; then
                    end=$next_pos
                fi
            else
                # No trailing space, try leading space
                if [[ $start -gt 0 ]]; then
                    local char="${line:$((start-1)):1}"
                    if [[ "$char" == " " || "$char" == $'\t' ]]; then
                        ((start--))
                    fi
                fi
            fi
            ;;

        aW)
            # around WORD: WORD + trailing space (or leading space if no trailing)
            # First calculate inner WORD range
            local iW_range
            iW_range=$(calculate_word_range "$line" "$cursor_x" "iW")
            read -r start end <<< "$iW_range"

            # Try to include trailing space (end+1 position)
            local next_pos=$((end + 1))
            if [[ $next_pos -lt $line_length ]]; then
                local char="${line:$next_pos:1}"
                if [[ "$char" == " " || "$char" == $'\t' ]]; then
                    end=$next_pos
                fi
            else
                # No trailing space, try leading space
                if [[ $start -gt 0 ]]; then
                    local char="${line:$((start-1)):1}"
                    if [[ "$char" == " " || "$char" == $'\t' ]]; then
                        ((start--))
                    fi
                fi
            fi
            ;;

        *)
            echo "Error: Unknown text-object type: $text_object" >&2
            echo ""
            return
            ;;
    esac

    # Return range as inclusive indices
    # For iw/iW: end is already pointing one past the last character, so we need end-1
    # For aw/aW: end was adjusted and is already pointing to the last character (inclusive)
    # But we need to return it consistently
    echo "$start $end"
}

# Main execution (when called from tmux)
main() {
    echo "=== text-object-yank.sh DEBUG ===" >> "$DEBUG_LOG"
    echo "Timestamp: $(date)" >> "$DEBUG_LOG"
    echo "Text-object type: $TEXT_OBJECT" >> "$DEBUG_LOG"

    # Check if text-object type is provided
    if [[ -z "$TEXT_OBJECT" ]]; then
        echo "Error: Text-object type is required" >&2
        echo "ERROR: No text-object type provided" >> "$DEBUG_LOG"
        exit 1
    fi

    # Get cursor position from copy-mode
    # In copy-mode, we need to use copy_cursor_x and copy_cursor_y
    local cursor_x
    local cursor_y
    cursor_x=$(tmux display-message -p '#{copy_cursor_x}')
    cursor_y=$(tmux display-message -p '#{copy_cursor_y}')

    echo "Copy-mode cursor position: x=$cursor_x, y=$cursor_y" >> "$DEBUG_LOG"

    # Get the scroll position in copy-mode
    local scroll_position
    scroll_position=$(tmux display-message -p '#{scroll_position}')

    echo "Scroll position: $scroll_position" >> "$DEBUG_LOG"

    # Calculate the actual line number to capture
    # copy_cursor_y is relative to the top of the visible pane
    # We need to capture from the scrollback buffer
    local pane_height
    pane_height=$(tmux display-message -p '#{pane_height}')

    # Get current line content using copy_cursor_y
    # capture-pane with -p captures the visible pane content
    # We need to get the line at the cursor position in copy-mode
    local line
    line=$(tmux display-message -p '#{copy_cursor_line}')

    echo "Line content (from copy_cursor_line): '$line'" >> "$DEBUG_LOG"

    # Calculate word range
    local range
    range=$(calculate_word_range "$line" "$cursor_x" "$TEXT_OBJECT")

    echo "Calculated range: $range" >> "$DEBUG_LOG"

    if [[ -z "$range" ]]; then
        # No word found, exit copy-mode
        echo "ERROR: No range calculated" >> "$DEBUG_LOG"
        tmux send-keys -X cancel
        exit 0
    fi

    read -r start end <<< "$range"

    echo "Start: $start, End: $end" >> "$DEBUG_LOG"

    # Move cursor to start position and begin selection
    tmux send-keys -X start-of-line
    # Move to the correct column (start position)
    for ((i=0; i<start; i++)); do
        tmux send-keys -X cursor-right
    done

    echo "Moved cursor to start position: $start" >> "$DEBUG_LOG"

    # Begin selection
    tmux send-keys -X begin-selection

    echo "Began selection" >> "$DEBUG_LOG"

    # Move to end position (inclusive)
    local chars_to_select=$((end - start + 1))
    for ((i=0; i<chars_to_select-1; i++)); do
        tmux send-keys -X cursor-right
    done

    echo "Selected $chars_to_select characters" >> "$DEBUG_LOG"

    # Detect clipboard tool
    # Priority: WSL (clip.exe) > macOS (pbcopy) > Linux X11 (xclip) > Linux Wayland (wl-copy)
    local clipboard_cmd=""
    if command -v clip.exe >/dev/null 2>&1; then
        clipboard_cmd="clip.exe"
    elif command -v pbcopy >/dev/null 2>&1; then
        clipboard_cmd="pbcopy"
    elif command -v xclip >/dev/null 2>&1; then
        clipboard_cmd="xclip -selection clipboard"
    elif command -v wl-copy >/dev/null 2>&1; then
        clipboard_cmd="wl-copy"
    fi

    echo "Clipboard command: $clipboard_cmd" >> "$DEBUG_LOG"

    # Use tmux's copy-pipe-and-cancel (same as visual mode yank)
    if [[ -n "$clipboard_cmd" ]]; then
        tmux send-keys -X copy-pipe-and-cancel "$clipboard_cmd"
        echo "Used copy-pipe-and-cancel with: $clipboard_cmd" >> "$DEBUG_LOG"
    else
        # No clipboard tool, just use copy-selection-and-cancel
        tmux send-keys -X copy-selection-and-cancel
        echo "Used copy-selection-and-cancel (no clipboard tool)" >> "$DEBUG_LOG"
    fi

    echo "Done" >> "$DEBUG_LOG"
    echo "" >> "$DEBUG_LOG"
}

# Only run main if not being sourced (for testing)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
