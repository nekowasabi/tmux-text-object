#!/usr/bin/env bash
# Tests for process6: Plugin registration for development

test_tmux_conf_has_plugin_registration() {
    if [[ -f "$HOME/.tmux.conf" ]]; then
        # Check for either run-shell or @plugin registration
        if grep -q "repos/tmux-text-object" "$HOME/.tmux.conf"; then
            return 0
        fi
    fi
    echo "  .tmux.confにプラグイン登録が見つかりません"
    return 1
}

# Run tests
run_test "tmux.conf has plugin registration" test_tmux_conf_has_plugin_registration
