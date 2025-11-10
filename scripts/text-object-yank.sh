#!/usr/bin/env bash
# text-object-yank.sh: Yank text-objects in tmux copy-mode-vi
# Usage: text-object-yank.sh <text-object-type>
# text-object-type: iw, aw, iW, aW

set -u

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
    # Check if text-object type is provided
    if [[ -z "$TEXT_OBJECT" ]]; then
        echo "Error: Text-object type is required" >&2
        exit 1
    fi

    # Get cursor position and current line from tmux
    local cursor_x
    local cursor_y
    cursor_x=$(tmux display-message -p '#{cursor_x}')
    cursor_y=$(tmux display-message -p '#{cursor_y}')

    # Get current line content
    local line
    line=$(tmux capture-pane -p -J | sed -n "$((cursor_y + 1))p")

    # Calculate word range
    local range
    range=$(calculate_word_range "$line" "$cursor_x" "$TEXT_OBJECT")

    if [[ -z "$range" ]]; then
        # No word found, exit copy-mode
        tmux send-keys -X cancel
        exit 0
    fi

    read -r start end <<< "$range"

    # Extract the text
    local text="${line:$start:$((end - start + 1))}"

    # Detect clipboard tool
    local clipboard_cmd
    if command -v pbcopy >/dev/null 2>&1; then
        clipboard_cmd="pbcopy"
    elif command -v clip.exe >/dev/null 2>&1; then
        clipboard_cmd="clip.exe"
    elif command -v xclip >/dev/null 2>&1; then
        clipboard_cmd="xclip -selection clipboard"
    elif command -v wl-copy >/dev/null 2>&1; then
        clipboard_cmd="wl-copy"
    else
        # No clipboard tool found, just use tmux's buffer
        clipboard_cmd="cat"
    fi

    # Copy to clipboard and exit copy-mode
    echo -n "$text" | eval "$clipboard_cmd"
    tmux send-keys -X cancel
}

# Only run main if not being sourced (for testing)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
