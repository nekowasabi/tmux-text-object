# title: tmux vim-mode text-object ヤンク機能の実装（プラグイン方式）

## 概要
- tmuxのcopy-mode-viで、Vimのtext-object（`iw`, `aw`, `iW`, `aW`）を使った単語ヤンク機能を実現する
- TPM（Tmux Plugin Manager）対応のプラグインとして実装し、再利用可能で配布しやすい形式にする
- ヤンク後は自動的にcopy-modeを抜け、通常モードに戻る（Vimの`y`動作と同じ）

### goal
- tmuxのコピーモードで`iw`や`aw`を押すだけで、カーソル位置の単語を素早くヤンクできるようになる
- Vimと同じ感覚でtext-objectを使ってテキストをコピーできる
- プラグインとして公開することで、他のユーザーも簡単に利用可能にする

## 必須のルール
- 必ず `CLAUDE.md` を参照し、ルールを守ること

## 開発のゴール
- TPM対応のtmuxプラグインとして実装
- `iw` (inner word), `aw` (around word), `iW` (inner WORD), `aW` (around WORD) の4つを実装
- プラグイン構造：メインファイル（*.tmux）+ スクリプト（scripts/）
- pbcopyを使用してシステムクリップボードに連携
- GitHubで公開可能な品質とドキュメントを整備

## 実装仕様

### text-object定義
- **iw (inner word)**: Vimの単語定義に従う - `[a-zA-Z0-9_]` の連続
- **aw (around word)**: iw + 後方の空白（後方に空白がなければ前方の空白を含む）
- **iW (inner WORD)**: 空白以外の連続文字列
- **aW (around WORD)**: iW + 後方の空白（後方に空白がなければ前方の空白を含む）

### プラグイン構造
```
tmux-text-object/
├── text_object.tmux          # プラグインメインファイル（*.tmux形式）
├── scripts/
│   └── text-object-yank.sh   # ヤンク処理スクリプト
├── README.md                  # 使い方ドキュメント
├── LICENSE                    # ライセンス
└── .gitignore                 # Git除外設定
```

### 技術的アプローチ
- **プラグインメインファイル**: `text_object.tmux` でキーバインドを設定
  - スクリプトへの相対パスを `CURRENT_DIR` 変数で解決
  - キーテーブル `text-object-inner` と `text-object-around` を作成
- **キーバインド**: copy-mode-viで`i`を押すとinner、`a`を押すとaroundのテーブルに切り替え
- **範囲計算**: シェルスクリプトでtmuxのカーソル位置と行内容を取得し、text-objectの範囲を計算
- **ヤンク実行**: 計算した範囲を選択してpbcopyにパイプし、copy-modeを抜ける
- **TPM連携**: TPMが自動的に `*.tmux` ファイルを実行する仕組みを利用

### 制約事項
- pbcopyを使用（デフォルト、将来的にはクリップボードツールの自動検出も検討）
- 引用符やブラケットのtext-object（`i"`, `i(` など）は今回の実装対象外
- 単語とWORDのtext-objectのみに集中

## 生成AIの学習用コンテキスト

### tmux設定ファイル
- `/home/takets/.tmux.conf`
  - TPMの設定を追加
  - プラグイン登録を追加

### 参考プラグイン
- `tmux-plugins/tmux-yank` - クリップボード連携の参考
- `tmux-plugins/tpm` - プラグインマネージャーの仕様

### 環境情報
- tmux version: 3.4
- 現在のcopy-mode設定: vi mode有効、基本的なv/yバインディング設定済み
- プラグイン: 未使用（TPMを新規インストール）

## Process

### process1 TPMのインストールと初期設定
@target: `~/.tmux/plugins/tpm/`
@target: `~/.tmux.conf`
- [ ] TPMをクローン
  - `git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm`
- [ ] `~/.tmux.conf` にTPM設定を追加
  - `set -g @plugin 'tmux-plugins/tpm'` を追加
  - 最下部に `run '~/.tmux/plugins/tpm/tpm'` を追加
- [ ] tmux設定をリロード（`tmux source ~/.tmux.conf`）
- [ ] TPMが正常に動作することを確認

### process2 プラグインプロジェクトの作成
@target: `~/repos/tmux-text-object/`
- [ ] プロジェクトディレクトリを作成
  - `mkdir -p ~/repos/tmux-text-object/scripts`
- [ ] Git リポジトリを初期化
  - `cd ~/repos/tmux-text-object && git init`
- [ ] `.gitignore` ファイルを作成
  - エディタの一時ファイルなどを除外

### process3 プラグインメインファイルの作成
@target: `~/repos/tmux-text-object/text_object.tmux`
- [ ] `text_object.tmux` ファイルを作成
  - shebang: `#!/usr/bin/env bash`
  - `CURRENT_DIR` 変数でスクリプトディレクトリのパスを取得
  - キーテーブルの設定
    - `tmux bind-key -T copy-mode-vi i switch-client -T text-object-inner`
    - `tmux bind-key -T copy-mode-vi a switch-client -T text-object-around`
  - text-objectバインディング
    - `tmux bind-key -T text-object-inner w run-shell "$CURRENT_DIR/scripts/text-object-yank.sh iw"`
    - `tmux bind-key -T text-object-inner W run-shell "$CURRENT_DIR/scripts/text-object-yank.sh iW"`
    - `tmux bind-key -T text-object-around w run-shell "$CURRENT_DIR/scripts/text-object-yank.sh aw"`
    - `tmux bind-key -T text-object-around W run-shell "$CURRENT_DIR/scripts/text-object-yank.sh aW"`
- [ ] 実行権限を付与（`chmod +x text_object.tmux`）

### process4 ヤンクスクリプトの実装
@target: `~/repos/tmux-text-object/scripts/text-object-yank.sh`
- [ ] `text-object-yank.sh` シェルスクリプトを作成
  - shebang: `#!/usr/bin/env bash`
  - 引数として text-object タイプ（iw/aw/iW/aW）を受け取る
  - `tmux display-message -p` でカーソル位置（#{cursor_x}, #{cursor_y}）を取得
  - `tmux capture-pane -p` で現在の行内容を取得
  - カーソル位置から単語/WORDの開始・終了位置を計算
  - `tmux send-keys` で範囲を選択
  - `tmux send-keys -X copy-pipe-and-cancel "pbcopy"` でヤンクしてcopy-modeを抜ける
- [ ] 実行権限を付与（`chmod +x scripts/text-object-yank.sh`）

### process5 単語範囲計算ロジックの実装
@target: `~/repos/tmux-text-object/scripts/text-object-yank.sh`
- [ ] `iw`: カーソル位置から前後に `[a-zA-Z0-9_]` をスキャンして範囲を特定
- [ ] `aw`: `iw` の範囲 + 後方の空白（なければ前方の空白）
- [ ] `iW`: カーソル位置から前後に空白以外をスキャンして範囲を特定
- [ ] `aW`: `iW` の範囲 + 後方の空白（なければ前方の空白）
- [ ] エッジケース処理
  - カーソルが空白上にある場合
  - 行頭・行末の処理
  - 単語が見つからない場合のエラーハンドリング

### process6 プラグインの登録（開発用）
@target: `~/.tmux.conf`
@ref: `~/repos/tmux-text-object/text_object.tmux`
- [ ] ローカル開発用にプラグインを直接実行する設定を追加
  - `run-shell ~/repos/tmux-text-object/text_object.tmux`
  - または TPM形式: `set -g @plugin 'file:///$HOME/repos/tmux-text-object'`
- [ ] tmux設定をリロード

### process7 動作確認とテスト
- [ ] tmux設定をリロード（`tmux source-file ~/.tmux.conf`）
- [ ] copy-mode-vi（`Prefix + [`）に入る
- [ ] 各text-objectをテスト
  - `iw`: 単語内にカーソルを置いて`iw`を押し、単語のみがヤンクされることを確認
  - `aw`: 単語内にカーソルを置いて`aw`を押し、単語+空白がヤンクされることを確認
  - `iW`: WORD内にカーソルを置いて`iW`を押し、WORD全体がヤンクされることを確認
  - `aW`: WORD内にカーソルを置いて`aW`を押し、WORD+空白がヤンクされることを確認
- [ ] ヤンク後にcopy-modeが正しく抜けることを確認
- [ ] pbcopyでシステムクリップボードに正しくコピーされていることを確認

### process10 ユニットテスト
- [ ] 様々な入力パターンでテスト
  - 通常の単語: `hello`, `world123`, `variable_name`
  - 記号を含むWORD: `path/to/file`, `https://example.com`, `foo(bar)`
  - 行頭・行末の単語
  - 連続する空白の処理
- [ ] エラーケースの確認
  - 空白行でtext-objectを実行
  - 単語が存在しない位置での実行

### process20 README.mdの作成
@target: `~/repos/tmux-text-object/README.md`
- [ ] プラグインの概要説明
- [ ] インストール方法
  - TPM経由のインストール手順
  - 手動インストール手順
- [ ] 使い方
  - text-objectの種類と動作説明
  - キーバインドの一覧
  - 使用例（スクリーンショットまたはGIF）
- [ ] 設定オプション（将来の拡張用）
- [ ] トラブルシューティング
  - pbcopyが動作しない場合の対処法
  - キーバインドの衝突が発生した場合の対処法
- [ ] ライセンス情報
- [ ] 貢献方法

### process21 LICENSEファイルの作成
@target: `~/repos/tmux-text-object/LICENSE`
- [ ] ライセンスの選定（MIT、Apache 2.0、GPLv3など）
- [ ] LICENSEファイルを作成

### process50 フォローアップ

### process100 リファクタリング
@target: `~/repos/tmux-text-object/scripts/text-object-yank.sh`
- [ ] シェルスクリプトのコード整理とコメント追加
- [ ] 関数化してコードの可読性を向上
- [ ] パフォーマンス最適化（必要に応じて）
- [ ] エラーメッセージの改善
- [ ] デバッグ用のログ出力機能（オプション）

### process101 クリップボードツールの自動検出（拡張機能）
@target: `~/repos/tmux-text-object/scripts/text-object-yank.sh`
- [ ] クリップボードツールを自動検出する関数を追加
  - pbcopy（macOS）
  - clip.exe（WSL）
  - xclip（Linux X11）
  - wl-copy（Wayland）
- [ ] 設定オプション `@text_object_clipboard` で上書き可能にする
- [ ] README.mdに設定例を追加

### process200 Git コミットとGitHub公開
@target: `~/repos/tmux-text-object/`
- [ ] 初回コミット
  - `git add .`
  - `git commit -m "Initial commit: text-object yank plugin for tmux"`
- [ ] GitHubリポジトリを作成
- [ ] リモートリポジトリを追加
  - `git remote add origin https://github.com/username/tmux-text-object.git`
- [ ] プッシュ
  - `git push -u origin main`
- [ ] GitHubのREADMEが正しく表示されることを確認

### process201 TPM経由でのインストールテスト
@target: `~/.tmux.conf`
- [ ] 開発用の `run-shell` 設定を削除
- [ ] TPM形式のプラグイン登録に変更
  - `set -g @plugin 'username/tmux-text-object'`
- [ ] TPMでインストール（`Prefix + I`）
- [ ] 正常に動作することを確認

### process202 ドキュメンテーションの仕上げ
@target: `~/repos/tmux-text-object/README.md`
- [ ] デモGIFまたはスクリーンショットの追加
- [ ] バッジの追加（License、Version、GitHub Starsなど）
- [ ] CHANGELOGファイルの作成
- [ ] CONTRIBUTINGガイドの作成（オプション）
