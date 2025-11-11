# Technology Stack: tmux-text-object

## Architecture

### High-Level Design
tmux-text-object は、tmux のキーテーブルシステムとシェルスクリプトを組み合わせたプラグインアーキテクチャを採用しています。

```
text_object.tmux (エントリポイント)
    ↓
キーテーブル定義 (text-object-yank, text-object-inner, text-object-around)
    ↓
シェルスクリプト実行 (yank-handler.sh, text-object-yank.sh)
    ↓
tmux コマンド実行 + クリップボード操作
```

### Three-Tier Key Table System
1. **初期 'y' プレス**: `yank-handler.sh` がビジュアル/ノーマルモードを検出
   - ビジュアルモード: 標準ヤンク操作を実行
   - ノーマルモード: `text-object-yank` キーテーブルに切り替え
2. **テキストオブジェクト修飾子**: ノーマルモードで 'y' の後
   - `i` を押すと `text-object-inner` テーブルに切り替え
   - `a` を押すと `text-object-around` テーブルに切り替え
3. **オブジェクト指定子**: 最終キーでテキストオブジェクトタイプを決定
   - `w`, `W` for words
   - `"`, `'`, `` ` `` for quotes
   - `(`, `)`, `[`, `]`, `{`, `}`, `<`, `>` for brackets

## Technology Components

### Core Technologies
- **Bash**: スクリプト実装言語（tmux 環境で広く利用可能）
- **tmux**: ターゲットプラットフォーム（バージョン 2.4+）
- **copy-mode-vi**: tmux のコピーモード（`mode-keys vi` 設定が必要）

### Platform Dependencies
- **macOS**: `pbcopy` (プリインストール)
- **WSL**: `clip.exe` (デフォルトで利用可能)
- **Linux (X11)**: `xclip` (要インストール)
- **Linux (Wayland)**: `wl-copy` (wl-clipboard パッケージ)

### Plugin Manager Support
- **TPM (Tmux Plugin Manager)**: 推奨インストール方法
- **Manual Installation**: `run-shell` ディレクティブでの直接読み込みもサポート

## Project Structure

### File Organization
```
tmux-text-object/
├── text_object.tmux              # プラグインエントリポイント（キーバインディング定義）
├── scripts/
│   ├── yank-handler.sh           # 'y' キー押下時のモード判定
│   └── text-object-yank.sh       # テキストオブジェクト範囲計算とヤンク実行
├── tests/
│   └── test-runner.sh            # テストスイート実行
├── README.md                     # プロジェクトドキュメント
├── PLAN.md                       # 開発計画（クォート・ブラケット追加）
└── CHANGELOG.md                  # 変更履歴
```

### Key Files and Responsibilities

#### `text_object.tmux`
- プラグインの初期化スクリプト
- キーテーブルとキーバインディングの定義
- 3層のキーテーブル構造を構築:
  - `text-object-yank`: 初期 'y' プレス後
  - `text-object-inner`: `yi` プレス後（inner オブジェクト）
  - `text-object-around`: `ya` プレス後（around オブジェクト）

#### `scripts/yank-handler.sh`
- ビジュアルモード vs ノーマルモードの判定
- tmux の `#{selection_present}` フォーマット変数を使用
- 適切なヤンク動作にルーティング

#### `scripts/text-object-yank.sh`
- **calculate_word_range()**: テキストオブジェクトタイプに基づいて範囲を計算
  - Word/WORD: 正規表現パターンマッチング
  - Quote: 左右スキャンアルゴリズム
  - Bracket: ペア検索アルゴリズム
- **find_quote_range()**: クォートペアの検索と範囲計算
- **find_bracket_range()**: ブラケットペアの検索と範囲計算
- **get_bracket_pair()**: ブラケット文字からペアを決定
- テキスト抽出: `#{copy_cursor_line}` フォーマット変数を使用
- クリップボード操作: プラットフォーム検出と適切なコマンド実行

## Development Environment

### Required Tools
- **bash**: シェルスクリプト実行環境
- **tmux 2.4+**: テスト・開発環境
- **git**: バージョン管理
- **エディタ**: Vim/Neovim 推奨（tmux との統合が良好）

### Testing Setup
```bash
# テストスイート実行
./tests/test-runner.sh

# 個別テスト実行
./tests/test_process4_5.sh
```

### Local Development
```tmux
# ~/.tmux.conf での開発用ロード
run-shell ~/repos/tmux-text-object/text_object.tmux

# 設定リロード
tmux source-file ~/.tmux.conf

# キーバインディング確認
tmux list-keys -T text-object-inner
tmux list-keys -T text-object-around
```

## Common Commands

### Development Workflow
```bash
# 構文チェック
bash -n text_object.tmux
bash -n scripts/text-object-yank.sh
bash -n scripts/yank-handler.sh

# テスト実行
./tests/test-runner.sh

# tmux設定リロード
tmux source-file ~/.tmux.conf

# キーバインディング確認
tmux list-keys -T copy-mode-vi | grep text-object
tmux list-keys -T text-object-yank
tmux list-keys -T text-object-inner
tmux list-keys -T text-object-around

# デバッグ: tmux のフォーマット変数確認
tmux display-message -p "#{copy_cursor_line}"
tmux display-message -p "#{copy_cursor_x}"
tmux display-message -p "#{selection_present}"
```

### Installation Commands
```bash
# TPM経由（推奨）
# ~/.tmux.conf に追加:
# set -g @plugin 'nekowasabi/tmux-text-object'
# その後: prefix + I

# マニュアルインストール
git clone https://github.com/nekowasabi/tmux-text-object.git ~/.tmux/plugins/tmux-text-object
# ~/.tmux.conf に追加:
# run-shell ~/.tmux/plugins/tmux-text-object/text_object.tmux
tmux source-file ~/.tmux.conf
```

## Technical Constraints

### tmux API Limitations
- **#{copy_cursor_line}**: 現在行のテキストを取得（単一行のみ）
- **#{copy_cursor_x}**: カーソルの X 座標（0-indexed）
- **キーテーブル切り替え**: 一度に1つのキーテーブルのみアクティブ

### Algorithm Constraints
- **シンプルマッチング**: ネストされたブラケット/クォートは正確に処理されない
- **単一行制限**: 複数行にまたがるテキストオブジェクトは非対応
- **エスケープ非対応**: `\"` や `\(` などのエスケープシーケンスは特別扱いされない

## Security Considerations

### Safe Practices
- **クリップボード内容**: ユーザーが明示的に選択したテキストのみをコピー
- **シェルインジェクション防止**: tmux コマンドのパラメータはクォートで適切にエスケープ
- **ファイルシステムアクセス**: プラグインは読み取り専用（システムファイルへの書き込みなし）

### Privacy
- **ネットワーク通信なし**: すべての処理はローカル環境で完結
- **外部依存なし**: bash と tmux のみで動作（サードパーティライブラリ不要）
