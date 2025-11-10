#!/usr/bin/env bash
# Simple test runner for tmux-text-object

set -u

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PASSED=0
FAILED=0

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

run_test() {
    local test_name="$1"
    local test_func="$2"

    if $test_func; then
        echo -e "${GREEN}✓${NC} $test_name"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}✗${NC} $test_name"
        ((FAILED++))
        return 1
    fi
}

assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-値が一致しません}"

    if [[ "$expected" == "$actual" ]]; then
        return 0
    else
        echo "  Expected: $expected"
        echo "  Actual:   $actual"
        echo "  $message"
        return 1
    fi
}

assert_file_exists() {
    local file="$1"
    if [[ -f "$file" ]]; then
        return 0
    else
        echo "  ファイルが存在しません: $file"
        return 1
    fi
}

assert_executable() {
    local file="$1"
    if [[ -x "$file" ]]; then
        return 0
    else
        echo "  ファイルに実行権限がありません: $file"
        return 1
    fi
}

# Load all test files
for test_file in "$TEST_DIR"/test_*.sh; do
    if [[ -f "$test_file" ]]; then
        echo ""
        echo "=========================================="
        echo "Running: $(basename "$test_file")"
        echo "=========================================="
        source "$test_file"
    fi
done

# Summary
echo ""
echo "=========================================="
echo "Test Results:"
echo "  Passed: $PASSED"
echo "  Failed: $FAILED"
echo "=========================================="

if [[ $FAILED -gt 0 ]]; then
    exit 1
fi

exit 0
