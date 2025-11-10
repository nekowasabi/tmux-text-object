#!/usr/bin/env bash
# Tests for process1: TPM installation and initial setup

test_tpm_directory_exists() {
    assert_file_exists "$HOME/.tmux/plugins/tpm/tpm"
}

test_tmux_conf_has_tpm_plugin() {
    if [[ -f "$HOME/.tmux.conf" ]]; then
        if grep -q "@plugin 'tmux-plugins/tpm'" "$HOME/.tmux.conf"; then
            return 0
        fi
    fi
    echo "  .tmux.confにTPMプラグイン設定が見つかりません"
    return 1
}

test_tmux_conf_has_tpm_run() {
    if [[ -f "$HOME/.tmux.conf" ]]; then
        if grep -q "run.*tpm/tpm" "$HOME/.tmux.conf"; then
            return 0
        fi
    fi
    echo "  .tmux.confにTPM実行設定が見つかりません"
    return 1
}

# Run tests
run_test "TPM directory exists" test_tpm_directory_exists
run_test "tmux.conf has TPM plugin declaration" test_tmux_conf_has_tpm_plugin
run_test "tmux.conf has TPM run command" test_tmux_conf_has_tpm_run
