#!/usr/bin/env bash
# Unit tests for find_paragraph_range function

set -euo pipefail

# Test framework
TESTS_PASSED=0
TESTS_FAILED=0

# ANSI colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test result functions
assert_equals() {
    local expected="$1"
    local actual="$2"
    local test_name="$3"

    if [[ "$expected" == "$actual" ]]; then
        echo -e "${GREEN}✓${NC} $test_name"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗${NC} $test_name"
        echo "  Expected: '$expected'"
        echo "  Actual:   '$actual'"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Mock find_paragraph_range function for testing
# This simulates the function with mock data instead of tmux capture
find_paragraph_range_mock() {
    local cursor_y="$1"
    local mode="$2"
    local mock_data="$3"

    # Simulate reading lines from mock data
    local lines=()
    while IFS= read -r line || [[ -n "$line" ]]; do
        lines+=("$line")
    done <<< "$mock_data"

    local total_lines=${#lines[@]}

    if [[ $total_lines -eq 0 ]]; then
        echo ""
        return
    fi

    # For simplicity, cursor_y is directly the line index (no history_size calculation)
    local abs_line=$cursor_y

    # Safety check
    if [[ $abs_line -lt 0 || $abs_line -ge $total_lines ]]; then
        echo ""
        return
    fi

    # Check if current line is blank
    local current_line="${lines[$abs_line]}"
    if [[ -z "$current_line" || "$current_line" =~ ^[[:space:]]*$ ]]; then
        if [[ "$mode" == "inner" ]]; then
            echo ""
            return
        fi
    fi

    # Find paragraph start
    local para_start=$abs_line
    while [[ $para_start -gt 0 ]]; do
        local prev_line="${lines[$((para_start - 1))]}"
        if [[ -z "$prev_line" || "$prev_line" =~ ^[[:space:]]*$ ]]; then
            break
        fi
        ((para_start--))
    done

    # Find paragraph end
    local para_end=$abs_line
    while [[ $para_end -lt $((total_lines - 1)) ]]; do
        local next_line="${lines[$((para_end + 1))]}"
        if [[ -z "$next_line" || "$next_line" =~ ^[[:space:]]*$ ]]; then
            break
        fi
        ((para_end++))
    done

    # For "around" mode, include blank lines
    if [[ "$mode" == "around" ]]; then
        if [[ $para_start -gt 0 ]]; then
            local prev_line="${lines[$((para_start - 1))]}"
            if [[ -z "$prev_line" || "$prev_line" =~ ^[[:space:]]*$ ]]; then
                ((para_start--))
            fi
        fi

        if [[ $para_end -lt $((total_lines - 1)) ]]; then
            local next_line="${lines[$((para_end + 1))]}"
            if [[ -z "$next_line" || "$next_line" =~ ^[[:space:]]*$ ]]; then
                ((para_end++))
            fi
        fi
    fi

    echo "$para_start $para_end"
}

# Test cases
echo -e "${YELLOW}Running unit tests for find_paragraph_range...${NC}\n"

# Test 1: Single paragraph
MOCK_DATA_1="Line 1
Line 2
Line 3"
result=$(find_paragraph_range_mock 1 "inner" "$MOCK_DATA_1")
assert_equals "0 2" "$result" "Test 1: Single paragraph (middle line)"

# Test 2: Multiple paragraphs - first paragraph
MOCK_DATA_2="Para 1 Line 1
Para 1 Line 2

Para 2 Line 1
Para 2 Line 2"
result=$(find_paragraph_range_mock 0 "inner" "$MOCK_DATA_2")
assert_equals "0 1" "$result" "Test 2: First paragraph"

# Test 3: Multiple paragraphs - second paragraph
result=$(find_paragraph_range_mock 3 "inner" "$MOCK_DATA_2")
assert_equals "3 4" "$result" "Test 3: Second paragraph"

# Test 4: Cursor on blank line (inner mode)
result=$(find_paragraph_range_mock 2 "inner" "$MOCK_DATA_2")
assert_equals "" "$result" "Test 4: Blank line in inner mode returns empty"

# Test 5: Around mode - includes blank line before
result=$(find_paragraph_range_mock 3 "around" "$MOCK_DATA_2")
assert_equals "2 4" "$result" "Test 5: Around mode includes blank line before"

# Test 6: Paragraph at start of buffer
MOCK_DATA_3="First line
Second line

Third line"
result=$(find_paragraph_range_mock 0 "inner" "$MOCK_DATA_3")
assert_equals "0 1" "$result" "Test 6: Paragraph at buffer start"

# Test 7: Paragraph at end of buffer
result=$(find_paragraph_range_mock 3 "inner" "$MOCK_DATA_3")
assert_equals "3 3" "$result" "Test 7: Paragraph at buffer end"

# Test 8: Single line paragraph
MOCK_DATA_4="Line 1

Line 3

Line 5"
result=$(find_paragraph_range_mock 2 "inner" "$MOCK_DATA_4")
assert_equals "2 2" "$result" "Test 8: Single line paragraph"

# Test 9: Around mode with blank line after
result=$(find_paragraph_range_mock 2 "around" "$MOCK_DATA_4")
assert_equals "1 3" "$result" "Test 9: Around mode includes blank lines"

# Test 10: Large paragraph
MOCK_DATA_5="Line 1
Line 2
Line 3
Line 4
Line 5

Other"
result=$(find_paragraph_range_mock 2 "inner" "$MOCK_DATA_5")
assert_equals "0 4" "$result" "Test 10: Large paragraph (5 lines)"

# Summary
echo ""
echo "================================"
echo -e "Tests passed: ${GREEN}${TESTS_PASSED}${NC}"
echo -e "Tests failed: ${RED}${TESTS_FAILED}${NC}"
echo "================================"

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed!${NC}"
    exit 1
fi
