#!/usr/bin/env bash
# Tests for process20: README.md creation

PROJECT_ROOT="/home/takets/repos/tmux-text-object"

test_readme_exists() {
    assert_file_exists "$PROJECT_ROOT/README.md"
}

test_readme_has_title() {
    if grep -q "# tmux-text-object" "$PROJECT_ROOT/README.md"; then
        return 0
    fi
    echo "  README.mdにタイトルが見つかりません"
    return 1
}

test_readme_has_installation() {
    if grep -q "Installation" "$PROJECT_ROOT/README.md"; then
        return 0
    fi
    echo "  README.mdにインストール手順が見つかりません"
    return 1
}

test_readme_has_usage() {
    if grep -q "Usage" "$PROJECT_ROOT/README.md"; then
        return 0
    fi
    echo "  README.mdに使用方法が見つかりません"
    return 1
}

# Run tests
run_test "README.md exists" test_readme_exists
run_test "README.md has title" test_readme_has_title
run_test "README.md has installation section" test_readme_has_installation
run_test "README.md has usage section" test_readme_has_usage
