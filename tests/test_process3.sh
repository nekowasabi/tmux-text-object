#!/usr/bin/env bash
# Tests for process3: Plugin main file creation

PROJECT_ROOT="/home/takets/repos/tmux-text-object"

test_main_file_exists() {
    assert_file_exists "$PROJECT_ROOT/text_object.tmux"
}

test_main_file_executable() {
    assert_executable "$PROJECT_ROOT/text_object.tmux"
}

test_main_file_has_shebang() {
    local first_line
    first_line=$(head -n 1 "$PROJECT_ROOT/text_object.tmux")
    if [[ "$first_line" == "#!/usr/bin/env bash" ]]; then
        return 0
    fi
    echo "  shebangが正しくありません: $first_line"
    return 1
}

test_main_file_has_current_dir() {
    if grep -q "CURRENT_DIR" "$PROJECT_ROOT/text_object.tmux"; then
        return 0
    fi
    echo "  CURRENT_DIR変数が定義されていません"
    return 1
}

test_main_file_has_key_tables() {
    local file="$PROJECT_ROOT/text_object.tmux"
    if grep -q "text-object-inner" "$file" && grep -q "text-object-around" "$file"; then
        return 0
    fi
    echo "  キーテーブルの定義が見つかりません"
    return 1
}

test_main_file_has_text_object_bindings() {
    local file="$PROJECT_ROOT/text_object.tmux"
    local missing=()

    grep -q "text-object-yank.sh iw" "$file" || missing+=("iw")
    grep -q "text-object-yank.sh iW" "$file" || missing+=("iW")
    grep -q "text-object-yank.sh aw" "$file" || missing+=("aw")
    grep -q "text-object-yank.sh aW" "$file" || missing+=("aW")

    if [[ ${#missing[@]} -eq 0 ]]; then
        return 0
    fi
    echo "  text-objectバインディングが不足: ${missing[*]}"
    return 1
}

# Run tests
run_test "Main file exists" test_main_file_exists
run_test "Main file is executable" test_main_file_executable
run_test "Main file has correct shebang" test_main_file_has_shebang
run_test "Main file defines CURRENT_DIR" test_main_file_has_current_dir
run_test "Main file has key tables" test_main_file_has_key_tables
run_test "Main file has text-object bindings" test_main_file_has_text_object_bindings
