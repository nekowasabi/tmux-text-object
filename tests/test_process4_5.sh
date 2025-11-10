#!/usr/bin/env bash
# Tests for process4-5: Yank script and word range calculation

PROJECT_ROOT="/home/takets/repos/tmux-text-object"
SCRIPT_FILE="$PROJECT_ROOT/scripts/text-object-yank.sh"

test_yank_script_exists() {
    assert_file_exists "$SCRIPT_FILE"
}

test_yank_script_executable() {
    assert_executable "$SCRIPT_FILE"
}

test_yank_script_has_shebang() {
    local first_line
    first_line=$(head -n 1 "$SCRIPT_FILE")
    if [[ "$first_line" == "#!/usr/bin/env bash" ]]; then
        return 0
    fi
    echo "  shebangが正しくありません: $first_line"
    return 1
}

# Test word range calculation functions
test_calculate_iw_range() {
    # Source the script to test its functions
    source "$SCRIPT_FILE"

    # Test: "hello_world123 test" with cursor at position 5 (middle of "hello_world123")
    local line="hello_world123 test"
    local cursor_x=5
    local result
    result=$(calculate_word_range "$line" "$cursor_x" "iw")

    if [[ "$result" == "0 13" ]]; then
        return 0
    fi
    echo "  iw範囲計算が正しくありません: expected '0 13', got '$result'"
    return 1
}

test_calculate_iW_range() {
    source "$SCRIPT_FILE"

    # Test: "path/to/file.txt another" with cursor at position 5 (middle of "path/to/file.txt")
    local line="path/to/file.txt another"
    local cursor_x=5
    local result
    result=$(calculate_word_range "$line" "$cursor_x" "iW")

    if [[ "$result" == "0 15" ]]; then
        return 0
    fi
    echo "  iW範囲計算が正しくありません: expected '0 15', got '$result'"
    return 1
}

test_calculate_aw_range() {
    source "$SCRIPT_FILE"

    # Test: "hello world" with cursor at position 2 (middle of "hello")
    local line="hello world"
    local cursor_x=2
    local result
    result=$(calculate_word_range "$line" "$cursor_x" "aw")

    # "hello " (0-5, includes trailing space)
    if [[ "$result" == "0 5" ]]; then
        return 0
    fi
    echo "  aw範囲計算が正しくありません: expected '0 5', got '$result'"
    return 1
}

test_calculate_aW_range() {
    source "$SCRIPT_FILE"

    # Test: "foo/bar baz" with cursor at position 2 (middle of "foo/bar")
    local line="foo/bar baz"
    local cursor_x=2
    local result
    result=$(calculate_word_range "$line" "$cursor_x" "aW")

    # "foo/bar " (0-7, includes trailing space)
    if [[ "$result" == "0 7" ]]; then
        return 0
    fi
    echo "  aW範囲計算が正しくありません: expected '0 7', got '$result'"
    return 1
}

# Run tests
run_test "Yank script exists" test_yank_script_exists
run_test "Yank script is executable" test_yank_script_executable
run_test "Yank script has correct shebang" test_yank_script_has_shebang
run_test "Calculate iw range" test_calculate_iw_range
run_test "Calculate iW range" test_calculate_iW_range
run_test "Calculate aw range" test_calculate_aw_range
run_test "Calculate aW range" test_calculate_aW_range
