#!/usr/bin/env bash
# text-object-yank.sh: Yank text-objects in tmux copy-mode-vi
# Usage: text-object-yank.sh <text-object-type>
#
# Supported text-object types:
#   Word objects: iw, aw, iW, aW
#   Quote objects: i", a", i', a', i`, a`
#   Bracket objects: i(, a(, i), a), i[, a[, i], a], i{, a{, i}, a}, i<, a<, i>, a>
#
# Note: Quote and bracket matching uses simple algorithm (no nesting support)

set -u

# Debug log file
DEBUG_LOG="/tmp/tmux-text-object-debug.log"

# Text-object type (iw, aw, iW, aW)
TEXT_OBJECT="${1:-}"

# Find quote range using simple matching algorithm
#
# This function finds the nearest pair of quotes surrounding the cursor position.
# It first searches left from the cursor to find a quote, then attempts to find
# its matching pair by searching right. If no closing quote is found, it assumes
# the first quote was a closing quote and searches left for an opening quote.
#
# Arguments:
#   line       - The line of text to search in
#   cursor_x   - Current cursor position (0-indexed)
#   quote_char - The quote character to search for (", ', or `)
#   mode       - "inner" (exclude quotes) or "around" (include quotes)
#
# Returns: "start end" (inclusive range) or "" if no pair found
#
# Note: Does not handle escaped quotes or nested structures
find_quote_range() {
    local line="$1"
    local cursor_x="$2"
    local quote_char="$3"
    local mode="$4"

    # Search left for nearest quote (from cursor position, inclusive)
    local first_quote=-1
    for ((i=cursor_x; i>=0; i--)); do
        if [[ "${line:i:1}" == "$quote_char" ]]; then
            first_quote=$i
            break
        fi
    done

    # If no quote found on the left, return empty
    if [[ $first_quote -eq -1 ]]; then
        echo ""
        return
    fi

    # Try to find a closing quote after the first quote
    local start=-1
    local end=-1
    for ((i=first_quote+1; i<${#line}; i++)); do
        if [[ "${line:i:1}" == "$quote_char" ]]; then
            # Found a pair: first_quote is opening, i is closing
            start=$first_quote
            end=$i
            break
        fi
    done

    # If no closing quote found, the first_quote might be a closing quote
    # Search for an opening quote before it
    if [[ $end -eq -1 ]]; then
        for ((i=first_quote-1; i>=0; i--)); do
            if [[ "${line:i:1}" == "$quote_char" ]]; then
                start=$i
                end=$first_quote
                break
            fi
        done
    fi

    # If still no pair found, return empty
    if [[ $start -eq -1 || $end -eq -1 ]]; then
        echo ""
        return
    fi

    # Calculate range based on mode
    if [[ "$mode" == "inner" ]]; then
        # inner: exclude quotes (content between quotes)
        echo "$((start+1)) $((end-1))"
    else
        # around: include quotes
        echo "$start $end"
    fi
}

# Get matching bracket pair
#
# Given a bracket character (opening or closing), returns the corresponding
# opening and closing bracket pair.
#
# Arguments:
#   bracket - A bracket character: (, ), [, ], {, }, <, or >
#
# Returns: "open_bracket close_bracket" or "" if invalid bracket
get_bracket_pair() {
    local bracket="$1"
    case "$bracket" in
        '('|')') echo "( )" ;;
        '['|']') echo "[ ]" ;;
        '{'|'}') echo "{ }" ;;
        '<'|'>') echo "< >" ;;
        *) echo "" ;;
    esac
}

# Find bracket range using simple matching algorithm
#
# This function finds the nearest pair of brackets surrounding the cursor position.
# Unlike quote matching (where opening and closing are identical), brackets have
# distinct opening and closing characters. The algorithm searches left from the
# cursor for either bracket type, then searches in the appropriate direction for
# its matching pair.
#
# Arguments:
#   line          - The line of text to search in
#   cursor_x      - Current cursor position (0-indexed)
#   open_bracket  - The opening bracket character
#   close_bracket - The closing bracket character
#   mode          - "inner" (exclude brackets) or "around" (include brackets)
#
# Returns: "start end" (inclusive range) or "" if no pair found
#
# Note: Uses simple matching - does not handle nested brackets correctly
find_bracket_range() {
    local line="$1"
    local cursor_x="$2"
    local open_bracket="$3"
    local close_bracket="$4"
    local mode="$5"

    # Search left for nearest bracket (from cursor position, inclusive)
    local first_bracket=-1
    local first_bracket_char=""
    for ((i=cursor_x; i>=0; i--)); do
        local char="${line:i:1}"
        if [[ "$char" == "$open_bracket" || "$char" == "$close_bracket" ]]; then
            first_bracket=$i
            first_bracket_char="$char"
            break
        fi
    done

    # If no bracket found on the left, return empty
    if [[ $first_bracket -eq -1 ]]; then
        echo ""
        return
    fi

    # Try to find a matching bracket
    local start=-1
    local end=-1

    if [[ "$first_bracket_char" == "$open_bracket" ]]; then
        # First bracket is opening, search right for closing
        for ((i=first_bracket+1; i<${#line}; i++)); do
            if [[ "${line:i:1}" == "$close_bracket" ]]; then
                start=$first_bracket
                end=$i
                break
            fi
        done
    else
        # First bracket is closing, search left for opening
        for ((i=first_bracket-1; i>=0; i--)); do
            if [[ "${line:i:1}" == "$open_bracket" ]]; then
                start=$i
                end=$first_bracket
                break
            fi
        done
    fi

    # If no pair found, return empty
    if [[ $start -eq -1 || $end -eq -1 ]]; then
        echo ""
        return
    fi

    # Calculate range based on mode
    if [[ "$mode" == "inner" ]]; then
        # inner: exclude brackets
        echo "$((start+1)) $((end-1))"
    else
        # around: include brackets
        echo "$start $end"
    fi
}

# Find paragraph range using blank line detection
#
# This function finds a paragraph (text block separated by blank lines)
# surrounding the cursor position. It searches up and down from the cursor
# to find blank lines that delimit the paragraph.
#
# Arguments:
#   cursor_y - Current cursor Y position (line number, 0-indexed from visible pane top)
#   mode     - "inner" (exclude blank lines) or "around" (include surrounding blank lines)
#
# Returns: "start_line end_line" (inclusive line range, 0-indexed from capture-pane output)
#          or "" if cursor is on a blank line (for inner mode)
#
# Note: Uses tmux capture-pane to get all visible lines in the pane
find_paragraph_range() {
    local cursor_y="$1"
    local mode="$2"

    # Capture all visible lines from the pane
    # Note: This captures from the scrollback buffer
    local lines
    mapfile -t lines < <(tmux capture-pane -p)

    local total_lines=${#lines[@]}

    # Get scroll position to calculate absolute line number
    local scroll_position
    scroll_position=$(tmux display-message -p '#{scroll_position}')

    # Calculate absolute line number in the capture
    # In copy-mode, cursor_y is relative to the top of the visible pane
    # scroll_position tells us how many lines we've scrolled back
    local abs_line=$((cursor_y + scroll_position))

    # Safety check: ensure abs_line is within bounds
    if [[ $abs_line -lt 0 || $abs_line -ge $total_lines ]]; then
        echo ""
        return
    fi

    # Check if current line is blank
    local current_line="${lines[$abs_line]}"
    if [[ -z "$current_line" || "$current_line" =~ ^[[:space:]]*$ ]]; then
        if [[ "$mode" == "inner" ]]; then
            # For inner mode, don't select blank lines
            echo ""
            return
        fi
    fi

    # Find paragraph start (search upward for blank line or start of buffer)
    local para_start=$abs_line
    while [[ $para_start -gt 0 ]]; do
        local prev_line="${lines[$((para_start - 1))]}"
        if [[ -z "$prev_line" || "$prev_line" =~ ^[[:space:]]*$ ]]; then
            # Found blank line above
            break
        fi
        ((para_start--))
    done

    # Find paragraph end (search downward for blank line or end of buffer)
    local para_end=$abs_line
    while [[ $para_end -lt $((total_lines - 1)) ]]; do
        local next_line="${lines[$((para_end + 1))]}"
        if [[ -z "$next_line" || "$next_line" =~ ^[[:space:]]*$ ]]; then
            # Found blank line below
            break
        fi
        ((para_end++))
    done

    # For "around" mode, include one blank line before and after (if they exist)
    if [[ "$mode" == "around" ]]; then
        # Include blank line before (if exists)
        if [[ $para_start -gt 0 ]]; then
            local prev_line="${lines[$((para_start - 1))]}"
            if [[ -z "$prev_line" || "$prev_line" =~ ^[[:space:]]*$ ]]; then
                ((para_start--))
            fi
        fi

        # Include blank line after (if exists)
        if [[ $para_end -lt $((total_lines - 1)) ]]; then
            local next_line="${lines[$((para_end + 1))]}"
            if [[ -z "$next_line" || "$next_line" =~ ^[[:space:]]*$ ]]; then
                ((para_end++))
            fi
        fi
    fi

    echo "$para_start $para_end"
}

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

        # Quote text-objects (inner)
        'i"'|"i'"|'i`')
            local quote_char="${text_object:1:1}"  # Extract ", ', or `
            local range=$(find_quote_range "$line" "$cursor_x" "$quote_char" "inner")
            echo "$range"
            return
            ;;

        # Quote text-objects (around)
        'a"'|"a'"|'a`')
            local quote_char="${text_object:1:1}"
            local range=$(find_quote_range "$line" "$cursor_x" "$quote_char" "around")
            echo "$range"
            return
            ;;

        # Bracket text-objects (inner)
        'i('|'i)'|'i['|'i]'|'i{'|'i}'|'i<'|'i>')
            local bracket="${text_object:1:1}"
            local pair=$(get_bracket_pair "$bracket")
            local open_bracket="${pair%% *}"
            local close_bracket="${pair##* }"
            local range=$(find_bracket_range "$line" "$cursor_x" "$open_bracket" "$close_bracket" "inner")
            echo "$range"
            return
            ;;

        # Bracket text-objects (around)
        'a('|'a)'|'a['|'a]'|'a{'|'a}'|'a<'|'a>')
            local bracket="${text_object:1:1}"
            local pair=$(get_bracket_pair "$bracket")
            local open_bracket="${pair%% *}"
            local close_bracket="${pair##* }"
            local range=$(find_bracket_range "$line" "$cursor_x" "$open_bracket" "$close_bracket" "around")
            echo "$range"
            return
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

    # Handle paragraph text-objects separately (multi-line)
    if [[ "$TEXT_OBJECT" == "ip" || "$TEXT_OBJECT" == "ap" ]]; then
        echo "Processing paragraph text-object: $TEXT_OBJECT" >> "$DEBUG_LOG"

        # Determine mode (inner or around)
        local mode="inner"
        if [[ "$TEXT_OBJECT" == "ap" ]]; then
            mode="around"
        fi

        # Find paragraph range
        local para_range
        para_range=$(find_paragraph_range "$cursor_y" "$mode")

        echo "Paragraph range: $para_range" >> "$DEBUG_LOG"

        if [[ -z "$para_range" ]]; then
            # No paragraph found (e.g., cursor on blank line in inner mode)
            echo "ERROR: No paragraph range calculated" >> "$DEBUG_LOG"
            tmux send-keys -X cancel
            exit 0
        fi

        local start_line end_line
        read -r start_line end_line <<< "$para_range"

        echo "Paragraph lines: start=$start_line, end=$end_line" >> "$DEBUG_LOG"

        # Capture all lines and extract the paragraph
        local lines
        mapfile -t lines < <(tmux capture-pane -p)

        # Extract paragraph text (join lines with newlines)
        local selected_text=""
        for ((i=start_line; i<=end_line; i++)); do
            if [[ $i -eq $start_line ]]; then
                selected_text="${lines[$i]}"
            else
                selected_text="${selected_text}"$'\n'"${lines[$i]}"
            fi
        done

        echo "Selected paragraph text:" >> "$DEBUG_LOG"
        echo "$selected_text" >> "$DEBUG_LOG"

        # Detect clipboard tool
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

        # Copy to system clipboard (if available)
        if [[ -n "$clipboard_cmd" ]]; then
            echo -n "$selected_text" | eval "$clipboard_cmd"
            echo "Copied to system clipboard with: $clipboard_cmd" >> "$DEBUG_LOG"
        fi

        # Copy to tmux buffer
        tmux set-buffer -- "$selected_text"
        echo "Copied to tmux buffer" >> "$DEBUG_LOG"

        # Exit copy-mode
        tmux send-keys -X cancel

        echo "Done (paragraph)" >> "$DEBUG_LOG"
        echo "" >> "$DEBUG_LOG"
        exit 0
    fi

    # Original single-line text-object handling
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

    # Extract selected text directly (NO CURSOR MOVEMENT!)
    local selected_text="${line:$start:$((end - start + 1))}"

    echo "Selected text: '$selected_text'" >> "$DEBUG_LOG"

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

    # Copy to system clipboard (if available)
    if [[ -n "$clipboard_cmd" ]]; then
        echo -n "$selected_text" | eval "$clipboard_cmd"
        echo "Copied to system clipboard with: $clipboard_cmd" >> "$DEBUG_LOG"
    fi

    # Copy to tmux buffer
    tmux set-buffer -- "$selected_text"
    echo "Copied to tmux buffer" >> "$DEBUG_LOG"

    # Exit copy-mode
    tmux send-keys -X cancel

    echo "Done" >> "$DEBUG_LOG"
    echo "" >> "$DEBUG_LOG"
}

# Only run main if not being sourced (for testing)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
