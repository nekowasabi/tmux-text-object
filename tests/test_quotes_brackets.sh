#!/usr/bin/env bash
# Tests for quote and bracket text-objects

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"

# Source the yank script to test calculate_word_range function
source "$PARENT_DIR/scripts/text-object-yank.sh"

PASSED=0
FAILED=0

# Test helper function
test_range() {
    local description="$1"
    local line="$2"
    local cursor_x="$3"
    local text_object="$4"
    local expected="$5"

    local result=$(calculate_word_range "$line" "$cursor_x" "$text_object")

    if [[ "$result" == "$expected" ]]; then
        echo "✓ $description"
        ((PASSED++))
    else
        echo "✗ $description"
        echo "  Expected: $expected"
        echo "  Got:      $result"
        ((FAILED++))
    fi
}

echo "=== Double Quote Tests ==="
test_range 'yi" - hello world' 'echo "hello world"' 11 'i"' '6 16'
test_range 'ya" - hello world' 'echo "hello world"' 11 'a"' '5 17'
test_range 'yi" - cursor on quote' 'echo "hello world"' 5 'i"' '6 16'
test_range 'yi" - no closing quote' 'echo "hello world' 11 'i"' ''
test_range 'yi" - no opening quote' 'echo hello world"' 11 'i"' ''

echo ""
echo "=== Single Quote Tests ==="
test_range "yi' - test string" "echo 'test string'" 11 "i'" '6 16'
test_range "ya' - test string" "echo 'test string'" 11 "a'" '5 17'

echo ""
echo "=== Backtick Tests ==="
test_range 'yi` - date' 'cmd `date` output' 9 'i`' '5 8'
test_range 'ya` - date' 'cmd `date` output' 9 'a`' '4 9'

echo ""
echo "=== Parentheses Tests ==="
test_range 'yi( - arg1, arg2' 'func(arg1, arg2)' 8 'i(' '5 14'
test_range 'ya( - arg1, arg2' 'func(arg1, arg2)' 8 'a(' '4 15'
test_range 'yi) - same as yi(' 'func(arg1, arg2)' 8 'i)' '5 14'
test_range 'ya) - same as ya(' 'func(arg1, arg2)' 8 'a)' '4 15'

echo ""
echo "=== Square Brackets Tests ==="
test_range 'yi[ - index' 'array[index]' 8 'i[' '6 10'
test_range 'ya[ - index' 'array[index]' 8 'a[' '5 11'

echo ""
echo "=== Curly Braces Tests ==="
test_range 'yi{ - key: value' 'object{key: value}' 10 'i{' '7 16'
test_range 'ya{ - key: value' 'object{key: value}' 10 'a{' '6 17'

echo ""
echo "=== Angle Brackets Tests ==="
test_range 'yi< - tag' '<tag>content</tag>' 2 'i<' '1 3'
test_range 'ya< - tag' '<tag>content</tag>' 2 'a<' '0 4'

echo ""
echo "=== Test Summary ==="
echo "Passed: $PASSED"
echo "Failed: $FAILED"

if [[ $FAILED -eq 0 ]]; then
    echo "All tests passed!"
    exit 0
else
    echo "Some tests failed."
    exit 1
fi
