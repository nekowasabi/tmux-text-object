# title: tmux text-object クオート・ブラケット対応の追加実装

## 概要
- tmuxのcopy-mode-viで、既存のword/WORDテキストオブジェクトに加えて、クオートとブラケットのテキストオブジェクト機能を実装する
- Vimの `yi"`, `ya(`, `yi[` などと同等の機能を提供し、より柔軟なテキストヤンクを可能にする
- 既存のプラグイン構造を拡張し、22個の新しいテキストオブジェクトを追加する

### goal
- tmuxのコピーモードで `yi"` や `ya(` などを使って、クオートやブラケット内のテキストを素早くヤンクできるようになる
- Vimと同じ感覚でクオート・ブラケットのtext-objectを使ってテキストをコピーできる
- 既存のiw/aw/iW/aW機能を維持しながら、シームレスに新機能を追加する

## 必須のルール
- 必ず `CLAUDE.md` を参照し、ルールを守ること

## 開発のゴール
- **クオート系テキストオブジェクト**: yi", ya", yi', ya', yi`, ya` の6個を実装
- **ブラケット系テキストオブジェクト**: yi(, ya(, yi), ya), yi[, ya[, yi], ya], yi{, ya{, yi}, ya}, yi<, ya<, yi>, ya> の16個を実装
- **合計22個**の新しいキーバインディングを追加
- 単純マッチングアルゴリズムによる実装(ネスト非対応)
- inner(クオート/ブラケット内のみ) と around(クオート/ブラケットを含む) の両方に対応

## 実装仕様

### 対象テキストオブジェクト

#### クオート系 (6個)
- **yi"** / **ya"**: ダブルクオート内/ダブルクオートを含む範囲
- **yi'** / **ya'**: シングルクオート内/シングルクオートを含む範囲
- **yi`** / **ya`**: バッククオート内/バッククオートを含む範囲

#### ブラケット系 (16個)
- **yi(** / **ya(** (または **yi)** / **ya)**): 丸括弧内/丸括弧を含む範囲
- **yi[** / **ya[** (または **yi]** / **ya]**): 角括弧内/角括弧を含む範囲
- **yi{** / **ya{** (または **yi}** / **ya}**): 波括弧内/波括弧を含む範囲
- **yi<** / **ya<** (または **yi>** / **ya>**): 山括弧内/山括弧を含む範囲

### 技術的アプローチ

#### 既存実装の分析結果
- **キーバインディング追加箇所**: `text_object.tmux` (行14-32)
  - `tmux bind-key -T text-object-inner` でinnerテーブルに登録
  - `tmux bind-key -T text-object-around` でaroundテーブルに登録
- **範囲計算ロジック**: `scripts/text-object-yank.sh` の `calculate_word_range` 関数 (行17-163)
  - case文で各テキストオブジェクトタイプを処理
  - 戻り値形式: "start end" (包含的な範囲、0-indexed)
- **ヤンク実行ロジック**: `scripts/text-object-yank.sh` (行224-269)
  - カーソル移動 → 選択開始 → 選択終了 → copy-pipe-and-cancel の流れ
  - 変更不要(そのまま利用可能)

#### クオート検索アルゴリズム
1. カーソル位置から左方向にスキャンして開きクオートを検索
2. カーソル位置から右方向にスキャンして閉じクオートを検索
3. inner: クオート自体を含まない範囲 (start+1, end-1)
4. around: クオート自体を含む範囲 (start, end)
5. ペアが見つからない場合は空文字列を返す

#### ブラケット検索アルゴリズム
1. ブラケット文字から開き/閉じペアを決定
2. カーソル位置から左方向にスキャンして開きブラケットを検索(単純マッチング)
3. カーソル位置から右方向にスキャンして閉じブラケットを検索(単純マッチング)
4. inner: ブラケット自体を含まない範囲 (start+1, end-1)
5. around: ブラケット自体を含む範囲 (start, end)
6. ペアが見つからない場合は空文字列を返す
7. **注意**: ネスト対応はせず、最も近いペアをマッチング

### 制約事項
- **ネスト非対応**: `func(foo(bar))` のような場合、内側の括弧を正確に扱わない可能性
- **エスケープ非対応**: `\"` や `\'` などのエスケープシーケンスは考慮しない
- **単一行のみ**: 複数行にまたがるクオート/ブラケットには対応しない(既存のiw/aWと同じ制約)
- **単純マッチング**: カーソル位置から最も近いペアを検索するシンプルなアルゴリズム

### 実装の影響範囲
- **text_object.tmux**: 22個のキーバインディング追加 (約22行)
- **scripts/text-object-yank.sh**:
  - `find_quote_range()` 関数を追加 (約40行)
  - `get_bracket_pair()` 関数を追加 (約10行)
  - `find_bracket_range()` 関数を追加 (約40行)
  - `calculate_word_range()` 関数にcase文を追加 (約30行)
  - 合計約120行追加
- **tests/test_quotes_brackets.sh**: 新規テストファイル作成 (約200行)
- **README.md**: Features, Usage, Examples, Text-Object Definitions セクション更新 (約50行追加)

## 生成AIの学習用コンテキスト

### 既存ファイル
- `/Users/ttakeda/repos/tmux-text-object/text_object.tmux`
  - プラグインメインファイル
  - 既存のキーバインディング定義を参照
- `/Users/ttakeda/repos/tmux-text-object/scripts/text-object-yank.sh`
  - ヤンク処理の本体
  - `calculate_word_range` 関数の実装パターンを参照
- `/Users/ttakeda/repos/tmux-text-object/tests/test_process4_5.sh`
  - 既存のテストパターンを参照

### 参考情報
- 既存実装の分析: Plan mode 冒頭のTask実行結果を参照
- Vimのテキストオブジェクト仕様: `:help text-objects` 相当の動作を目指す

## Process

### process1 クオート検索ロジックの実装
@target: `/Users/ttakeda/repos/tmux-text-object/scripts/text-object-yank.sh`
@ref: 既存の `calculate_word_range` 関数 (行17-163)

#### sub1 find_quote_range() ヘルパー関数の作成
- [ ] `calculate_word_range` 関数の前に `find_quote_range()` 関数を追加 (行16付近に挿入)
  - 関数シグネチャ: `find_quote_range(line, cursor_x, quote_char, mode)`
  - 引数説明をコメントで記述
- [ ] 左方向スキャンロジックの実装
  ```bash
  local start=-1
  for ((i=cursor_x; i>=0; i--)); do
    if [[ "${line:i:1}" == "$quote_char" ]]; then
      start=$i
      break
    fi
  done
  ```
- [ ] 右方向スキャンロジックの実装
  ```bash
  local end=-1
  for ((i=cursor_x+1; i<${#line}; i++)); do
    if [[ "${line:i:1}" == "$quote_char" ]]; then
      end=$i
      break
    fi
  done
  ```
- [ ] ペアが見つからない場合のエラーハンドリング
  - `start == -1` または `end == -1` の場合は空文字列 "" を返す
- [ ] inner/around の範囲計算
  - inner: `echo "$((start+1)) $((end-1))"`
  - around: `echo "$start $end"`

#### sub2 calculate_word_range へのクオートケース追加
- [ ] `calculate_word_range` 関数の case 文に新しいケースを追加 (行156付近、既存の `*)` ケースの前に挿入)
  ```bash
  # Quote text-objects
  'i"'|"i'"|'i`')
    local quote_char="${text_object:1:1}"  # Extract ", ', or `
    local range=$(find_quote_range "$line" "$cursor_x" "$quote_char" "inner")
    echo "$range"
    return
    ;;
  'a"'|"a'"|'a`')
    local quote_char="${text_object:1:1}"
    local range=$(find_quote_range "$line" "$cursor_x" "$quote_char" "around")
    echo "$range"
    return
    ;;
  ```

#### sub3 クオート検索の動作確認
- [ ] シェルスクリプトの構文チェック (`bash -n text-object-yank.sh`)
- [ ] 簡単なテストケースで動作確認
  - 入力: `echo "hello world"`
  - 期待: yi" で "hello world" (6 17) を返す

### process2 ブラケット検索ロジックの実装
@target: `/Users/ttakeda/repos/tmux-text-object/scripts/text-object-yank.sh`
@ref: `find_quote_range` 関数 (process1で作成)

#### sub1 get_bracket_pair() ヘルパー関数の作成
- [ ] `find_quote_range` 関数の後に `get_bracket_pair()` 関数を追加
  - 関数シグネチャ: `get_bracket_pair(bracket)`
  - 戻り値: "開きブラケット 閉じブラケット"
- [ ] ブラケットペアの定義
  ```bash
  get_bracket_pair() {
    local bracket="$1"
    case "$bracket" in
      '('|')') echo "( )" ;;
      '['|']') echo "[ ]" ;;
      '{'|'}') echo "{ }" ;;
      '<'|'>') echo "< >" ;;
      *) echo "" ;;
    esac
  }
  ```

#### sub2 find_bracket_range() ヘルパー関数の作成
- [ ] `get_bracket_pair` 関数の後に `find_bracket_range()` 関数を追加
  - 関数シグネチャ: `find_bracket_range(line, cursor_x, open_bracket, close_bracket, mode)`
  - 引数説明をコメントで記述
- [ ] 左方向スキャンロジックの実装(単純マッチング)
  ```bash
  local start=-1
  for ((i=cursor_x; i>=0; i--)); do
    local char="${line:i:1}"
    if [[ "$char" == "$open_bracket" ]]; then
      start=$i
      break
    fi
  done
  ```
- [ ] 右方向スキャンロジックの実装(単純マッチング)
  ```bash
  local end=-1
  for ((i=cursor_x+1; i<${#line}; i++)); do
    local char="${line:i:1}"
    if [[ "$char" == "$close_bracket" ]]; then
      end=$i
      break
    fi
  done
  ```
- [ ] ペアが見つからない場合のエラーハンドリング
  - `start == -1` または `end == -1` の場合は空文字列 "" を返す
- [ ] inner/around の範囲計算
  - inner: `echo "$((start+1)) $((end-1))"`
  - around: `echo "$start $end"`

#### sub3 calculate_word_range へのブラケットケース追加
- [ ] `calculate_word_range` 関数の case 文に新しいケースを追加 (クオートケースの後に挿入)
  ```bash
  # Bracket text-objects (inner)
  'i('|'i)'|'i['|'i]'|'i{'|'i}'|'i<'|'i>')
    local bracket="${text_object:1:1}"
    local pair=$(get_bracket_pair "$bracket")
    local open_bracket="${pair%% *}"
    local close_bracket="${pair##* }"
    local range=$(find_bracket_range "$line" "$cursor_x" "$open_bracket" "$close_bracket" "inner")
    echo "$range"
    return
    ;;

  # Bracket text-objects (around)
  'a('|'a)'|'a['|'a]'|'a{'|'a}'|'a<'|'a>')
    local bracket="${text_object:1:1}"
    local pair=$(get_bracket_pair "$bracket")
    local open_bracket="${pair%% *}"
    local close_bracket="${pair##* }"
    local range=$(find_bracket_range "$line" "$cursor_x" "$open_bracket" "$close_bracket" "around")
    echo "$range"
    return
    ;;
  ```

#### sub4 ブラケット検索の動作確認
- [ ] シェルスクリプトの構文チェック (`bash -n text-object-yank.sh`)
- [ ] 簡単なテストケースで動作確認
  - 入力: `func(arg1, arg2)`
  - 期待: yi( で "arg1, arg2" (5 15) を返す

### process3 キーバインディングの追加
@target: `/Users/ttakeda/repos/tmux-text-object/text_object.tmux`
@ref: 既存のキーバインディング (行14-32)

#### sub1 クオート系キーバインディングの追加
- [ ] text-object-inner テーブルにクオートキーを追加 (行24付近、既存の `w` `W` バインディングの後に挿入)
  ```bash
  # Quote text-objects (inner)
  tmux bind-key -T text-object-inner '"' run-shell "$CURRENT_DIR/scripts/text-object-yank.sh 'i\"'"
  tmux bind-key -T text-object-inner "'" run-shell "$CURRENT_DIR/scripts/text-object-yank.sh \"i'\""
  tmux bind-key -T text-object-inner '`' run-shell "$CURRENT_DIR/scripts/text-object-yank.sh 'i\`'"
  ```
- [ ] text-object-around テーブルにクオートキーを追加 (行30付近、既存の `w` `W` バインディングの後に挿入)
  ```bash
  # Quote text-objects (around)
  tmux bind-key -T text-object-around '"' run-shell "$CURRENT_DIR/scripts/text-object-yank.sh 'a\"'"
  tmux bind-key -T text-object-around "'" run-shell "$CURRENT_DIR/scripts/text-object-yank.sh \"a'\""
  tmux bind-key -T text-object-around '`' run-shell "$CURRENT_DIR/scripts/text-object-yank.sh 'a\`'"
  ```

#### sub2 ブラケット系キーバインディングの追加
- [ ] text-object-inner テーブルにブラケットキーを追加 (クオートバインディングの後に挿入)
  ```bash
  # Bracket text-objects (inner)
  tmux bind-key -T text-object-inner '(' run-shell "$CURRENT_DIR/scripts/text-object-yank.sh 'i('"
  tmux bind-key -T text-object-inner ')' run-shell "$CURRENT_DIR/scripts/text-object-yank.sh 'i)'"
  tmux bind-key -T text-object-inner '[' run-shell "$CURRENT_DIR/scripts/text-object-yank.sh 'i['"
  tmux bind-key -T text-object-inner ']' run-shell "$CURRENT_DIR/scripts/text-object-yank.sh 'i]'"
  tmux bind-key -T text-object-inner '{' run-shell "$CURRENT_DIR/scripts/text-object-yank.sh 'i{'"
  tmux bind-key -T text-object-inner '}' run-shell "$CURRENT_DIR/scripts/text-object-yank.sh 'i}'"
  tmux bind-key -T text-object-inner '<' run-shell "$CURRENT_DIR/scripts/text-object-yank.sh 'i<'"
  tmux bind-key -T text-object-inner '>' run-shell "$CURRENT_DIR/scripts/text-object-yank.sh 'i>'"
  ```
- [ ] text-object-around テーブルにブラケットキーを追加 (クオートバインディングの後に挿入)
  ```bash
  # Bracket text-objects (around)
  tmux bind-key -T text-object-around '(' run-shell "$CURRENT_DIR/scripts/text-object-yank.sh 'a('"
  tmux bind-key -T text-object-around ')' run-shell "$CURRENT_DIR/scripts/text-object-yank.sh 'a)'"
  tmux bind-key -T text-object-around '[' run-shell "$CURRENT_DIR/scripts/text-object-yank.sh 'a['"
  tmux bind-key -T text-object-around ']' run-shell "$CURRENT_DIR/scripts/text-object-yank.sh 'a]'"
  tmux bind-key -T text-object-around '{' run-shell "$CURRENT_DIR/scripts/text-object-yank.sh 'a{'"
  tmux bind-key -T text-object-around '}' run-shell "$CURRENT_DIR/scripts/text-object-yank.sh 'a}'"
  tmux bind-key -T text-object-around '<' run-shell "$CURRENT_DIR/scripts/text-object-yank.sh 'a<'"
  tmux bind-key -T text-object-around '>' run-shell "$CURRENT_DIR/scripts/text-object-yank.sh 'a>'"
  ```

#### sub3 キーバインディングの整合性確認
- [ ] 既存のw/Wバインディングとの衝突がないことを確認
- [ ] tmuxの特殊文字エスケープが正しく処理されることを確認
- [ ] tmux設定をリロード (`tmux source-file ~/.tmux.conf`) してエラーがないことを確認

### process4 テストケースの作成
@target: `/Users/ttakeda/repos/tmux-text-object/tests/test_quotes_brackets.sh` (新規)
@ref: `tests/test_process4_5.sh` (既存のテストパターン)

#### sub1 テストフレームワークの準備
- [ ] `tests/test_quotes_brackets.sh` ファイルを作成
  - shebang: `#!/usr/bin/env bash`
  - 実行権限を付与 (`chmod +x tests/test_quotes_brackets.sh`)
- [ ] テストヘッダーとカウンターの初期化
  ```bash
  #!/usr/bin/env bash

  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  PARENT_DIR="$(dirname "$SCRIPT_DIR")"

  # Source the yank script to test calculate_word_range function
  source "$PARENT_DIR/scripts/text-object-yank.sh"

  PASSED=0
  FAILED=0
  ```
- [ ] テストヘルパー関数の作成
  ```bash
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
  ```

#### sub2 クオートテキストオブジェクトのテストケース
- [ ] ダブルクオート (") のテスト
  ```bash
  echo "=== Double Quote Tests ==="
  test_range 'yi" - hello world' 'echo "hello world"' 11 'i"' '6 17'
  test_range 'ya" - hello world' 'echo "hello world"' 11 'a"' '5 18'
  test_range 'yi" - cursor on quote' 'echo "hello world"' 5 'i"' '6 17'
  test_range 'yi" - no closing quote' 'echo "hello world' 11 'i"' ''
  test_range 'yi" - no opening quote' 'echo hello world"' 11 'i"' ''
  ```
- [ ] シングルクオート (') のテスト
  ```bash
  echo "=== Single Quote Tests ==="
  test_range "yi' - test string" "echo 'test string'" 11 "i'" '6 17'
  test_range "ya' - test string" "echo 'test string'" 11 "a'" '5 18'
  ```
- [ ] バッククオート (`) のテスト
  ```bash
  echo "=== Backtick Tests ==="
  test_range 'yi` - date' 'cmd `date` output' 9 'i`' '5 9'
  test_range 'ya` - date' 'cmd `date` output' 9 'a`' '4 10'
  ```

#### sub3 ブラケットテキストオブジェクトのテストケース
- [ ] 丸括弧 () のテスト
  ```bash
  echo "=== Parentheses Tests ==="
  test_range 'yi( - arg1, arg2' 'func(arg1, arg2)' 8 'i(' '5 15'
  test_range 'ya( - arg1, arg2' 'func(arg1, arg2)' 8 'a(' '4 16'
  test_range 'yi) - same as yi(' 'func(arg1, arg2)' 8 'i)' '5 15'
  test_range 'ya) - same as ya(' 'func(arg1, arg2)' 8 'a)' '4 16'
  ```
- [ ] 角括弧 [] のテスト
  ```bash
  echo "=== Square Brackets Tests ==="
  test_range 'yi[ - index' 'array[index]' 8 'i[' '6 11'
  test_range 'ya[ - index' 'array[index]' 8 'a[' '5 12'
  ```
- [ ] 波括弧 {} のテスト
  ```bash
  echo "=== Curly Braces Tests ==="
  test_range 'yi{ - key: value' 'object{key: value}' 10 'i{' '7 18'
  test_range 'ya{ - key: value' 'object{key: value}' 10 'a{' '6 19'
  ```
- [ ] 山括弧 <> のテスト
  ```bash
  echo "=== Angle Brackets Tests ==="
  test_range 'yi< - tag' '<tag>content</tag>' 2 'i<' '1 4'
  test_range 'ya< - tag' '<tag>content</tag>' 2 'a<' '0 5'
  ```

#### sub4 テストの実行とレポート
- [ ] テスト結果のサマリー出力
  ```bash
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
  ```
- [ ] `tests/test-runner.sh` に新しいテストファイルを追加
  - `./tests/test_quotes_brackets.sh` を実行リストに追加

### process5 README.md の更新
@target: `/Users/ttakeda/repos/tmux-text-object/README.md`
@ref: 既存の README.md (全体)

#### sub1 Features セクションの更新
- [ ] 既存の Features セクション (行9-16) を拡張
- [ ] Word/WORD, Quote, Bracket の3つのサブセクションに分割
  ```markdown
  ## Features

  ### Word/WORD Text Objects
  - **iw (inner word)**: Yank a word (alphanumeric and underscore characters)
  - **aw (around word)**: Yank a word plus surrounding whitespace
  - **iW (inner WORD)**: Yank a WORD (non-whitespace characters)
  - **aW (around WORD)**: Yank a WORD plus surrounding whitespace

  ### Quote Text Objects
  - **i"** / **a"**: Yank inside/around double quotes
  - **i'** / **a'**: Yank inside/around single quotes
  - **i`** / **a`**: Yank inside/around backticks

  ### Bracket Text Objects
  - **i(** / **a(** (or **i)** / **a)**): Yank inside/around parentheses
  - **i[** / **a[** (or **i]** / **a]**): Yank inside/around square brackets
  - **i{** / **a{** (or **i}** / **a}**): Yank inside/around curly braces
  - **i<** / **a<** (or **i>** / **a>**): Yank inside/around angle brackets

  - Automatically exits copy-mode after yanking (just like Vim's `y` operator)
  - Cross-platform clipboard support (pbcopy, clip.exe, xclip, wl-copy)
  ```

#### sub2 Usage セクションの更新
- [ ] text-object コマンドリスト (行63-66) を拡張
  ```markdown
  3. Use text-object commands (Vim-style):
     **Word/WORD Objects:**
     - `yiw`: Yank inner word
     - `yaw`: Yank around word (including surrounding space)
     - `yiW`: Yank inner WORD
     - `yaW`: Yank around WORD (including surrounding space)

     **Quote Objects:**
     - `yi"`: Yank inside double quotes
     - `ya"`: Yank around double quotes
     - `yi'`: Yank inside single quotes
     - `ya'`: Yank around single quotes
     - `yi``: Yank inside backticks
     - `ya``: Yank around backticks

     **Bracket Objects:**
     - `yi(` or `yi)`: Yank inside parentheses
     - `ya(` or `ya)`: Yank around parentheses
     - `yi[` or `yi]`: Yank inside square brackets
     - `ya[` or `ya]`: Yank around square brackets
     - `yi{` or `yi}`: Yank inside curly braces
     - `ya{` or `ya}`: Yank around curly braces
     - `yi<` or `yi>`: Yank inside angle brackets
     - `ya<` or `ya>`: Yank around angle brackets
  ```

#### sub3 Examples セクションの更新
- [ ] クオート・ブラケットの使用例を追加 (行78付近に挿入)
  ```markdown
  ### Quote Examples

  Given the text: `echo "hello world" 'test'`

  - Cursor on "hello" + `yi"` → yanks `hello world` (without quotes)
  - Cursor on "hello" + `ya"` → yanks `"hello world"` (with quotes)
  - Cursor on "test" + `yi'` → yanks `test`
  - Cursor on "test" + `ya'` → yanks `'test'`

  ### Bracket Examples

  Given the text: `func(arg1, arg2)`

  - Cursor on "arg1" + `yi(` → yanks `arg1, arg2`
  - Cursor on "arg1" + `ya(` → yanks `(arg1, arg2)`

  Given the text: `array[0]`

  - Cursor on "0" + `yi[` → yanks `0`
  - Cursor on "0" + `ya[` → yanks `[0]`

  Given the text: `{key: value}`

  - Cursor on "key" + `yi{` → yanks `key: value`
  - Cursor on "key" + `ya{` → yanks `{key: value}`
  ```

#### sub4 Text-Object Definitions セクションの更新
- [ ] Quote と Bracket の説明を追加 (行93付近、Word vs WORD の後に挿入)
  ```markdown
  ### Quote Text Objects

  - **Quotes**: Double quotes `"`, single quotes `'`, and backticks `` ` ``
  - **Inner (i)**: Selects text inside quotes (excludes quote characters)
  - **Around (a)**: Selects text including quotes

  ### Bracket Text Objects

  - **Brackets**: Parentheses `()`, square brackets `[]`, curly braces `{}`, angle brackets `<>`
  - **Inner (i)**: Selects text inside brackets (excludes bracket characters)
  - **Around (a)**: Selects text including brackets
  - **Note**: Uses simple matching (finds nearest pair, does not handle nested brackets)
  ```

### process10 ユニットテスト
- [ ] `./tests/test_quotes_brackets.sh` を実行して全テストがpassすることを確認
- [ ] エッジケースの追加テスト
  - 空文字列の行でtext-objectを実行
  - クオート/ブラケットが1つだけの場合
  - カーソルがクオート/ブラケット上にある場合
  - 複数のクオート/ブラケットが連続している場合

### process20 動作確認とテスト
@ref: 既存の process7 (動作確認手順)

#### sub1 tmux設定のリロードと基本動作確認
- [ ] tmux設定をリロード (`tmux source-file ~/.tmux.conf`)
- [ ] copy-mode-vi に入る (`Prefix + [`)
- [ ] `tmux list-keys -T text-object-inner` でクオート・ブラケットのキーバインディングが登録されていることを確認
- [ ] `tmux list-keys -T text-object-around` でクオート・ブラケットのキーバインディングが登録されていることを確認

#### sub2 クオートテキストオブジェクトの実地テスト
- [ ] `yi"` のテスト
  - テキスト: `echo "hello world"` を用意
  - カーソルを "hello" の上に移動
  - `yi"` を押して `hello world` がヤンクされることを確認(pbpaste で確認)
- [ ] `ya"` のテスト
  - 同じテキストで `ya"` を押して `"hello world"` がヤンクされることを確認
- [ ] `yi'`, `ya'`, `yi``, `ya`` も同様にテスト

#### sub3 ブラケットテキストオブジェクトの実地テスト
- [ ] `yi(` のテスト
  - テキスト: `func(arg1, arg2)` を用意
  - カーソルを "arg1" の上に移動
  - `yi(` を押して `arg1, arg2` がヤンクされることを確認
- [ ] `ya(` のテスト
  - 同じテキストで `ya(` を押して `(arg1, arg2)` がヤンクされることを確認
- [ ] `yi[`, `ya[`, `yi{`, `ya{`, `yi<`, `ya<` も同様にテスト

#### sub4 エッジケースの実地テスト
- [ ] クオート/ブラケットが見つからない場合の動作確認
  - ヤンクが実行されない、またはcopy-modeから抜けないことを確認
- [ ] カーソルがクオート/ブラケット上にある場合の動作確認
  - 正しく範囲が検出されてヤンクされることを確認
- [ ] 片方のペアのみ存在する場合の動作確認
  - エラーが発生せず、何もヤンクされないことを確認
- [ ] ヤンク後にcopy-modeが正しく抜けることを確認
- [ ] システムクリップボードに正しくコピーされていることを確認 (`pbpaste` コマンドで確認)

### process50 フォローアップ
- [ ] 将来の拡張案をドキュメント化
  - ネスト対応の実装方針
  - エスケープシーケンス対応
  - 複数行対応の可能性
- [ ] ユーザーからのフィードバックを収集するための Issue テンプレート作成

### process100 リファクタリング
@target: `/Users/ttakeda/repos/tmux-text-object/scripts/text-object-yank.sh`
- [ ] ヘルパー関数のコメント充実化
  - 各関数の目的、引数、戻り値を詳細に説明
- [ ] エラーハンドリングの改善
  - デバッグモード($DEBUG 環境変数)でエラーメッセージを出力
- [ ] コードの可読性向上
  - 変数名をより明確に
  - 複雑なロジックにコメントを追加
- [ ] パフォーマンスの確認
  - 長い行での動作テスト
  - 必要に応じて最適化

### process200 ドキュメンテーション
- [ ] CHANGELOG.md の更新
  - 新機能としてクオート・ブラケット対応を追加
  - バージョン番号を更新(例: v1.1.0)
- [ ] README.md の最終確認
  - スクリーンショットやGIFの追加を検討
  - インストール手順が最新か確認
- [ ] GitHub Issues/PRのテンプレート更新
  - 新機能に関するバグ報告用テンプレート
