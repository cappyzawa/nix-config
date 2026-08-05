# flow-retro

## 目的

レビュー層（diff-review / codex / verify / PR レビュー）の取り逃し記録を集計し、層の設定を調整する提案を作る。

## 発見

- `~/.claude/retro/flow.md` を読む。`^- ` で始まり、かつ同じ行に `<!-- triaged` が無い行だけが未処理エントリ（見出し・空行・コメントは queue に含めない）
- ファイルが無い・未処理ゼロなら仕事なし

## 実行

この loop の「1 件」は raw entry ではなく `should-have` と `kind` の組で作る pattern group:

1. 未処理エントリを `should-have` × `kind` で group 化する
2. 2 エントリ以上ある group について調整案を作る:
   - `diff-review` で捕まえるべきだった → `diff-review` skill の観点の追加、または land のレビュー手順への追加を提案
   - `codex` で捕まえるべきだった → codex skill のレビュー観点への追加を提案
   - `verify` で捕まえるべきだった → verify skill の surface 観点表、または譲れない点への追加を提案
   - `scope` → 省略不可リスト（CLAUDE.md）への追加を提案
   - `none` → 既存のどの層も所有していない。層の新設・拡張を提案するか、所有者が無いままである理由を述べる
   - `plan` → 層は 2026-08-05 に撤去済み。提案せず注記のみ（義務は §gap を測る / §ループ / verify へ移設した）
3. 調整案は nix-config の `config/claude/` への変更として draft PR で出す。1 エントリだけの group・文脈依存のエントリは提案せず triaged 注記のみ

## 検証

- 人間の PR レビュー（PR title / body は英語）

## 記録

- 処理した raw entry すべての行末に `<!-- triaged YYYY-MM-DD: <結果> -->` を追記する。行自体は消さない

## 上限

- 1 回の実行で pattern group 3 件まで（提案 PR に含める group 数の上限）
