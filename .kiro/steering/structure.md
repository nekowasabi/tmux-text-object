# Project Structure: tmux-text-object

## Root Directory Organization

```
tmux-text-object/
├── text_object.tmux              # プラグインエントリポイント
├── scripts/                      # 実行ロジック（bash スクリプト）
├── tests/                        # テストスイート
├── .kiro/                        # Kiro spec-driven development ファイル
├── .claude/                      # Claude Code 設定
├── README.md                     # プロジェクトドキュメント
├── PLAN.md                       # 開発計画書
├── CHANGELOG.md                  # 変更履歴
└── LICENSE                       # MIT ライセンス
```

## Subdirectory Structures

### `scripts/` - Core Logic
実装の中核となるシェルスクリプトを格納します。

```
scripts/
├── yank-handler.sh               # モード判定（ビジュアル vs ノーマル）
└── text-object-yank.sh           # テキストオブジェクト範囲計算とヤンク実行
```

**役割分担**:
- **yank-handler.sh**: 'y' キー押下時の初期処理。tmux の `#{selection_present}` を使ってモードを判定し、適切な処理にルーティング
- **text-object-yank.sh**: メインロジック。テキストオブジェクトの範囲を計算し、ヤンク操作を実行。以下の関数を含む:
  - `calculate_word_range()`: テキストオブジェクトタイプに基づいて範囲を計算（メイン関数）
  - `find_quote_range()`: クォートペアの検索
  - `find_bracket_range()`: ブラケットペアの検索
  - `get_bracket_pair()`: ブラケット文字からペアを決定

### `tests/` - Test Suite
ユニットテストと統合テストを格納します。

```
tests/
├── test-runner.sh                # テストスイート実行スクリプト
└── test_*.sh                     # 個別テストファイル
```

**テストパターン**:
- 各テストファイルは `calculate_word_range()` 関数を直接テスト
- `source` で `text-object-yank.sh` を読み込み、関数を直接呼び出し
- テストヘルパー関数 `test_range()` で期待値と実際の結果を比較

### `.kiro/` - Spec-Driven Development
Kiro スタイルの仕様駆動開発に関連するファイルを格納します。

```
.kiro/
├── steering/                     # AI ガイダンス用のプロジェクトコンテキスト
│   ├── product.md                # プロダクト概要
│   ├── tech.md                   # 技術スタック
│   └── structure.md              # プロジェクト構造（このファイル）
└── specs/                        # 機能仕様書（フィーチャー別）
    └── [feature-name]/           # 各機能の仕様（Requirements, Design, Tasks）
```

**Steering vs Specs**:
- **Steering**: プロジェクト全体のルールとコンテキスト（常に参照される）
- **Specs**: 個別機能の開発プロセスを形式化（フィーチャー別に管理）

### `.claude/` - Claude Code Configuration
Claude Code の設定とカスタムコマンドを格納します。

```
.claude/
├── commands/                     # スラッシュコマンド定義
└── CLAUDE.md                     # プロジェクト固有のプロンプト指示
```

## Code Organization Patterns

### キーバインディング定義パターン (`text_object.tmux`)
```bash
# キーテーブル定義
tmux bind-key -T [table-name] [key] [action]

# 例: text-object-inner テーブルに 'w' を登録
tmux bind-key -T text-object-inner 'w' run-shell "$CURRENT_DIR/scripts/text-object-yank.sh 'iw'"
```

**3層テーブル構造**:
1. `copy-mode-vi`: 'y' → `yank-handler.sh` を実行
2. `text-object-yank`: 'i' または 'a' を待機
3. `text-object-inner` / `text-object-around`: オブジェクト指定子を待機

### 範囲計算関数パターン (`text-object-yank.sh`)
```bash
calculate_word_range() {
  local line="$1"          # 現在行のテキスト
  local cursor_x="$2"      # カーソルの X 座標
  local text_object="$3"   # テキストオブジェクトタイプ（例: 'iw', 'yi"'）

  case "$text_object" in
    'iw'|'aw'|'iW'|'aW')
      # Word/WORD ロジック
      ;;
    'i"'|'a"'|"i'"|"a'"|'i`'|'a`')
      # Quote ロジック
      ;;
    'i('|'a('|...)
      # Bracket ロジック
      ;;
  esac

  echo "$start $end"  # 範囲を返す（0-indexed, 包含的）
}
```

**戻り値形式**: `"start end"` (空白区切り、0-indexed、包含的な範囲)

### テストパターン (`tests/test_*.sh`)
```bash
# テストファイル構造
source "$PARENT_DIR/scripts/text-object-yank.sh"  # 関数をロード

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

# テストケース
test_range 'iw - hello_world' 'hello_world test' 5 'iw' '0 11'
```

## File Naming Conventions

### Scripts
- **kebab-case**: `text-object-yank.sh`, `yank-handler.sh`
- **`.sh` 拡張子**: すべてのシェルスクリプトに付与
- **実行権限**: `chmod +x` で付与（テストファイルを含む）

### Tests
- **`test_` プレフィックス**: `test_quotes_brackets.sh`
- **機能名を含む**: テスト対象機能がファイル名から明確
- **`test-runner.sh`**: すべてのテストを実行するランナースクリプト

### Documentation
- **UPPERCASE**: `README.md`, `CHANGELOG.md`, `PLAN.md`, `LICENSE`
- **Markdown**: すべてのドキュメントは `.md` 拡張子

## Import Organization

### `source` による関数インポート
```bash
# テストファイルでの使用例
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"

source "$PARENT_DIR/scripts/text-object-yank.sh"
```

**パターン**:
- 絶対パスで `source` を使用（相対パスの曖昧性を回避）
- `BASH_SOURCE[0]` でスクリプトの場所を取得
- `$(dirname ...)` で親ディレクトリを計算

### `run-shell` による tmux スクリプト実行
```bash
# text_object.tmux での使用例
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

tmux bind-key -T text-object-inner 'w' run-shell "$CURRENT_DIR/scripts/text-object-yank.sh 'iw'"
```

**パターン**:
- `$CURRENT_DIR` 変数でプラグインルートを保存
- 絶対パスでスクリプトを参照（tmux 環境の多様性に対応）

## Key Architectural Principles

### 1. Separation of Concerns
- **キーバインディング定義** (`text_object.tmux`): tmux の設定
- **モード判定** (`yank-handler.sh`): ビジュアル/ノーマルモードの分岐
- **ロジック実装** (`text-object-yank.sh`): テキストオブジェクト範囲計算とヤンク実行
- **テスト** (`tests/`): ロジックの検証

### 2. Single Responsibility Principle
- 各関数は1つの明確な責任を持つ:
  - `calculate_word_range()`: 範囲計算のディスパッチ
  - `find_quote_range()`: クォート検索専用
  - `find_bracket_range()`: ブラケット検索専用
  - `get_bracket_pair()`: ブラケットペアマッピング専用

### 3. Testability
- 範囲計算ロジックは純粋関数として実装（副作用なし）
- `calculate_word_range()` は入力（line, cursor_x, text_object）から出力（範囲）を決定論的に生成
- テストファイルから直接関数を呼び出し可能（`source` で読み込み）

### 4. Minimal Dependencies
- bash と tmux のみに依存（外部ライブラリ不要）
- クリップボードツールはオプション（なくても tmux バッファには保存される）

### 5. Extensibility
- 新しいテキストオブジェクトの追加は簡単:
  1. `text_object.tmux` にキーバインディングを追加
  2. `calculate_word_range()` の `case` 文に新しいケースを追加
  3. 必要に応じてヘルパー関数を実装
  4. テストケースを追加

## Development Workflow Patterns

### 新機能追加の標準フロー
1. **計画**: `PLAN.md` で仕様を文書化
2. **ロジック実装**: `scripts/text-object-yank.sh` に関数を追加
3. **キーバインディング**: `text_object.tmux` にバインディングを追加
4. **テスト**: `tests/` に新しいテストファイルを作成
5. **ドキュメント**: `README.md` を更新
6. **履歴**: `CHANGELOG.md` に変更を記録

### ブランチ戦略
- **main**: 安定版（リリース可能）
- **feature/[feature-name]**: 新機能開発
- **fix/[issue-number]**: バグ修正

### コミットメッセージパターン
```
type(scope): subject

例:
feat(quotes): Add quote text-object support
fix(brackets): Fix bracket matching for edge cases
docs(readme): Update usage examples
test(quotes): Add tests for quote text-objects
```

**Type**:
- `feat`: 新機能
- `fix`: バグ修正
- `docs`: ドキュメント更新
- `test`: テスト追加・修正
- `refactor`: リファクタリング
