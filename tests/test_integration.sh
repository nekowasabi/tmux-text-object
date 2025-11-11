#!/usr/bin/env bash
# Integration tests for tmux text-object plugin
# Tests yip/yap commands in actual tmux environment

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(dirname "$SCRIPT_DIR")"

# Test framework
TESTS_PASSED=0
TESTS_FAILED=0

# ANSI colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Cleanup function
cleanup() {
    # Kill test tmux session if it exists
    tmux kill-session -t test-text-object 2>/dev/null || true
    # Clean up temp files
    rm -f /tmp/test-text-object-*
}

trap cleanup EXIT

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

# Create test tmux session with sample text
create_test_session() {
    local session_name="$1"
    local sample_text="$2"

    # Kill existing session if any
    tmux kill-session -t "$session_name" 2>/dev/null || true

    # Create new session
    tmux new-session -d -s "$session_name" -x 80 -y 24

    # Load the plugin
    tmux source-file "$PLUGIN_DIR/text_object.tmux"

    # Write sample text to the pane
    echo "$sample_text" > /tmp/test-text-object-sample.txt
    tmux send-keys -t "$session_name" "cat /tmp/test-text-object-sample.txt" Enter
    sleep 0.5  # Wait for output
}

# Execute yip command and capture result
test_yip_command() {
    local session_name="$1"
    local cursor_line="$2"
    local expected_output="$3"
    local test_name="$4"

    # Enter copy mode
    tmux send-keys -t "$session_name" C-b [
    sleep 0.2

    # Move to specified line (0-indexed from top of visible area)
    for ((i=0; i<cursor_line; i++)); do
        tmux send-keys -t "$session_name" Down
    done
    sleep 0.2

    # Execute yip
    tmux send-keys -t "$session_name" y i p
    sleep 0.3

    # Get tmux buffer content
    local actual_output
    actual_output=$(tmux show-buffer -b "" 2>/dev/null || echo "")

    # Compare
    assert_equals "$expected_output" "$actual_output" "$test_name"
}

echo -e "${YELLOW}Running integration tests for tmux text-object plugin...${NC}\n"

# Test 1: Simple single paragraph
SAMPLE_TEXT_1="Line 1
Line 2
Line 3"
create_test_session "test-text-object" "$SAMPLE_TEXT_1"
test_yip_command "test-text-object" 1 "Line 1
Line 2
Line 3" "Test 1: Simple single paragraph"

# Test 2: Multiple paragraphs - select first
SAMPLE_TEXT_2="Para 1 Line 1
Para 1 Line 2

Para 2 Line 1
Para 2 Line 2"
create_test_session "test-text-object" "$SAMPLE_TEXT_2"
test_yip_command "test-text-object" 1 "Para 1 Line 1
Para 1 Line 2" "Test 2: First paragraph in multi-paragraph text"

# Test 3: Multiple paragraphs - select second
create_test_session "test-text-object" "$SAMPLE_TEXT_2"
test_yip_command "test-text-object" 4 "Para 2 Line 1
Para 2 Line 2" "Test 3: Second paragraph in multi-paragraph text"

# Test 4: Single line paragraph
SAMPLE_TEXT_3="Line 1

Line 3

Line 5"
create_test_session "test-text-object" "$SAMPLE_TEXT_3"
test_yip_command "test-text-object" 3 "Line 3" "Test 4: Single line paragraph"

# Test 5: Large paragraph
SAMPLE_TEXT_4="Line 1
Line 2
Line 3
Line 4
Line 5

Other paragraph"
create_test_session "test-text-object" "$SAMPLE_TEXT_4"
test_yip_command "test-text-object" 3 "Line 1
Line 2
Line 3
Line 4
Line 5" "Test 5: Large paragraph (5 lines)"

# Cleanup
cleanup

# Summary
echo ""
echo "================================"
echo -e "Tests passed: ${GREEN}${TESTS_PASSED}${NC}"
echo -e "Tests failed: ${RED}${TESTS_FAILED}${NC}"
echo "================================"

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo -e "${GREEN}All integration tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some integration tests failed!${NC}"
    exit 1
fi
