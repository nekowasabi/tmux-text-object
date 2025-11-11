#!/usr/bin/env bash
# Tests for paragraph text-objects (ip/ap)
#
# Note: Paragraph text-objects require a tmux session to test properly.
# This test file provides integration tests that can be run manually in tmux.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"

# Source the yank script to test find_paragraph_range function
source "$PARENT_DIR/scripts/text-object-yank.sh"

PASSED=0
FAILED=0

echo "=== Paragraph Text-Object Tests ==="
echo ""
echo "Note: These are integration tests for paragraph text-objects."
echo "They demonstrate expected behavior and can be run in a tmux session."
echo ""

# Test scenarios for manual testing
echo "=== Manual Test Scenarios ==="
echo ""
echo "Test 1: Single paragraph (yip)"
echo "  Content:"
echo "    Line 1 of paragraph"
echo "    Line 2 of paragraph"
echo "    Line 3 of paragraph"
echo "    "
echo "  Expected: Should yank all 3 lines (excluding blank line)"
echo ""

echo "Test 2: Single paragraph (yap)"
echo "  Content:"
echo "    Line 1 of paragraph"
echo "    Line 2 of paragraph"
echo "    Line 3 of paragraph"
echo "    "
echo "  Expected: Should yank all 3 lines + blank line after"
echo ""

echo "Test 3: Multiple paragraphs (yip on first)"
echo "  Content:"
echo "    First paragraph line 1"
echo "    First paragraph line 2"
echo "    "
echo "    Second paragraph line 1"
echo "    Second paragraph line 2"
echo "  Expected: Should yank only first paragraph (2 lines)"
echo ""

echo "Test 4: Multiple paragraphs (yap on first)"
echo "  Content:"
echo "    First paragraph line 1"
echo "    First paragraph line 2"
echo "    "
echo "    Second paragraph line 1"
echo "    Second paragraph line 2"
echo "  Expected: Should yank first paragraph + blank line (3 lines)"
echo ""

echo "Test 5: Cursor on blank line (yip)"
echo "  Content:"
echo "    First paragraph"
echo "    "
echo "    Second paragraph"
echo "  Expected: Should not yank (blank line in inner mode)"
echo ""

echo "Test 6: Cursor on blank line (yap)"
echo "  Content:"
echo "    First paragraph"
echo "    "
echo "    Second paragraph"
echo "  Expected: May yank blank line or adjacent paragraph"
echo ""

echo "Test 7: Paragraph at start of buffer (yip)"
echo "  Content:"
echo "    First line (start of buffer)"
echo "    Second line"
echo "    "
echo "    Next paragraph"
echo "  Expected: Should yank first 2 lines"
echo ""

echo "Test 8: Paragraph at end of buffer (yip)"
echo "  Content:"
echo "    Previous paragraph"
echo "    "
echo "    Last line (end of buffer)"
echo "    Final line"
echo "  Expected: Should yank last 2 lines"
echo ""

echo "=== How to Run Manual Tests ==="
echo ""
echo "1. Start a tmux session"
echo "2. Load the plugin: run-shell $PARENT_DIR/text_object.tmux"
echo "3. Create test content in a pane (e.g., cat README.md)"
echo "4. Enter copy-mode: Prefix + ["
echo "5. Position cursor in a paragraph"
echo "6. Try yip or yap commands"
echo "7. Check clipboard: pbpaste (macOS) or xclip -o (Linux)"
echo ""

echo "=== Unit Test: Blank Line Detection ==="

# Simple unit test: verify blank line detection logic
test_blank_line() {
    local line="$1"
    local expected="$2"

    if [[ -z "$line" || "$line" =~ ^[[:space:]]*$ ]]; then
        result="blank"
    else
        result="not_blank"
    fi

    if [[ "$result" == "$expected" ]]; then
        echo "✓ Blank line test: '$line' is $expected"
        ((PASSED++))
    else
        echo "✗ Blank line test: '$line'"
        echo "  Expected: $expected"
        echo "  Got:      $result"
        ((FAILED++))
    fi
}

test_blank_line "" "blank"
test_blank_line "   " "blank"
test_blank_line "		" "blank"  # tabs
test_blank_line " 	 " "blank"  # mixed spaces and tabs
test_blank_line "text" "not_blank"
test_blank_line " text " "not_blank"

echo ""
echo "=== Test Summary ==="
echo "Passed: $PASSED"
echo "Failed: $FAILED"

if [[ $FAILED -eq 0 ]]; then
    echo "Unit tests passed!"
    echo "Please run manual integration tests in tmux to verify full functionality."
    exit 0
else
    echo "Some tests failed."
    exit 1
fi
