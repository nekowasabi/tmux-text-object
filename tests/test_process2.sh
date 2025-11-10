#!/usr/bin/env bash
# Tests for process2: Plugin project creation

PROJECT_ROOT="/home/takets/repos/tmux-text-object"

test_project_directory_exists() {
    if [[ -d "$PROJECT_ROOT" ]]; then
        return 0
    fi
    echo "  プロジェクトディレクトリが存在しません: $PROJECT_ROOT"
    return 1
}

test_scripts_directory_exists() {
    if [[ -d "$PROJECT_ROOT/scripts" ]]; then
        return 0
    fi
    echo "  scriptsディレクトリが存在しません"
    return 1
}

test_git_initialized() {
    if [[ -d "$PROJECT_ROOT/.git" ]]; then
        return 0
    fi
    echo "  Gitリポジトリが初期化されていません"
    return 1
}

test_gitignore_exists() {
    assert_file_exists "$PROJECT_ROOT/.gitignore"
}

# Run tests
run_test "Project directory exists" test_project_directory_exists
run_test "Scripts directory exists" test_scripts_directory_exists
run_test "Git repository initialized" test_git_initialized
run_test ".gitignore file exists" test_gitignore_exists
