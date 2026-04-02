# CLAUDE.md

@~/.claude/CLAUDE.local.md

## Common

- 会話は基本的に日本語で行います
  - 全角と半角の間に半角スペースを入れてしまう派です
  - 会話が日本語であれば構わないため、Thinking は英語でも問題ありません。
- 絵文字の使用は不要
- コードコメントは英語で記述すること

## Git

- cappyzawa 以外の repository では default branch への直接 push を避け、feature branch で PR を作成すること
- 全ての Commit は署名をしてください
  - `git commit -s`
- Commit Message は英語で記述してください
  - GitHub の予約語（Fixes, Closes, Resolves など）は使用しないでください
  - コミットメッセージは変更内容（Why/What）のみを記述し、How の箇条書きは不要

## Language

### Rust

- コードの提案を行うときは、それが `cargo clippy` で指摘事項がないかチェックしてください

## Pull Request

- PR は初回作成時に必ず draft で作成すること
- レビュー準備ができたら別途 `gh pr ready` で解除する

## GitHub へのアクセスについて

- Web の Fetch ではなく、github mcp server でアクセスしてください

## セカンドオピニオン

- ライブラリの API ドキュメント・使い方を調べるときは Context7 MCP (`resolve-library-id` → `get-library-docs`) を優先する
- 設計判断・ベストプラクティス・技術的な正しさの検証には `codex exec -s read-only` を使う
  - 例: `codex exec -s read-only "質問内容"`
- WebSearch は Context7 と codex のどちらでも解決できない場合の最終手段

## ツール使用の優先順位

Bash はシェル実行が必須なコマンドにのみ使うこと。以下は専用ツールで代替すること:

- ファイル検索: Glob (find / ls の代わり)
- ファイル内容検索: Grep (grep / rg の代わり)
- ファイル読み込み: Read (cat / head / tail の代わり)
- ファイル編集: Edit (sed / awk の代わり)
- ファイル作成: Write

## 開発手法

### TDD (テスト駆動開発)

開発タスクは原則 TDD で行うこと。TDD のサイクルは以下の順番で進める:

1. **Test (通ることを確認)** - 既存テストが通る状態を確認する
2. **Test 記述** - 新機能・修正に対応するテストを書く
3. **Test (RED)** - テストが失敗することを確認する
4. **ロジック記述** - テストを通すための最小限のコードを書く
5. **Test (Green)** - テストが通ることを確認する
6. **Refactor** - コードを整理・改善する
7. **Test (Green)** - リファクタ後もテストが通ることを確認する

## ワークフロー

- `.claude/rules/` へのルール追加・作成の提案があれば、auto memory 内の `rule-proposals.md` に書き溜めておくこと
  - 作業完了後にまとめてユーザーに提案する
  - glob でスコープを絞ること
