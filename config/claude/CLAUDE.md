# CLAUDE.md

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

## ワークフロー

- `.claude/rules/` へのルール追加・作成の提案があれば、auto memory 内の `rule-proposals.md` に書き溜めておくこと
  - 作業完了後にまとめてユーザーに提案する
  - glob でスコープを絞ること
