---
name: land
description: 実装完了後の品質パス（code-review --fix → codex レビュー → verify → retro 記録）を順に実行し、commit / PR 作成に進める状態にする。非自明な変更の完了報告・commit / PR 作成の前に使う。
---

# Land

実装が揃った変更を「出せる状態」にする品質パス。いつ実行するか・どこまで走らせるかは `~/.claude/CLAUDE.md` の「実装後レビュー」と「スコープ判断」が規定する。この skill は手順を持つ。

main セッション（control plane）で実行する。subagent 内では実行しない。

## 0. 入力を揃える

1. `git status --short` で untracked ファイルを確認し、新規ファイルは `git add -N <path>` して diff に含める（`git diff HEAD` だけだと untracked が対象から落ちる）
2. plan のパスが会話・呼び出し元から渡されていればそれを読む。渡されていなければ `~/.claude/plans/` から探す: 自前命名（`<repo>-<branch>.md`）はファイル名で、plan mode 由来のランダム slug ファイルは更新日時と中身で特定する（branch から再計算しない — worktree で branch 名が変わっていることがある）
3. **plan checkpoint 対象の変更なのに plan が見つからない場合は停止し**、ユーザーに確認して plan を復元してから続行する。「plan なし」として進めてよいのは、trivial な変更またはユーザーが plan なしを明示した変更のみ

## 1. code-review --fix

`/code-review` はモデルから起動できない（`disable-model-invocation`）。ユーザーに `/code-review --fix` の実行を依頼し、結果を受け取ってから step 2 へ進む。依頼時にレビュー対象（branch / staged diff）と、完了後に step 2 以降を続けることを伝える。

- 適用された修正が合意済み契約を変えていないか確認する。仕様・API・依存・テスト期待値に触る変更が入っていたら戻し、指摘として記録してユーザー / plan 判断に返す
- 適用した修正の要約を控える（step 2 で codex に同梱する）
- 対象がコードを含まない diff（ドキュメント・設定の文面のみ）ならスキップしてよい
- `simplify` で代替しない。品質改善専門でバグを探さないので、この層のカバレッジが落ちる

## 2. codex レビュー

スコープ判断で codex 省略可の変更ならスキップして step 3 へ。実行する場合は codex skill の手順に従い、プロンプトに以下を同梱する:

- diff（untracked 込み）
- plan の実行層（契約・non-goals・合格基準）。plan が無い場合は「plan なし」と明記し、ユーザー要求・既存挙動との乖離を観点にする
- step 1 で適用した修正の要約

指摘の裁定は CLAUDE.md「指摘事項の扱い」に従う。

## 3. verify

指摘対応が終わったら、変更種別に応じた最小十分な検証を行う:

- runtime surface のある変更 → verify skill があればそれで実際に動かして確認する。verify skill が無い環境では、plan の合格基準とプロジェクト規約から最小十分な実行確認を自分で組む
- 無い変更でも typecheck / lint / config validation 等の該当する静的検証を実行する
- 実行できなかった検証は理由を完了報告に残す

## 4. retro 記録

step 1〜3 で critical な問題（バグ・契約違反・セキュリティ）が見つかった場合、`~/.claude/retro/flow.md` に 1 行追記する（ファイル・ディレクトリが無ければ作る）:

```
- <YYYY-MM-DD> repo:<repo> found-by:<code-review|codex|verify|pr-ai|pr-human> should-have:<plan|code-review|codex|verify|scope> kind:<bug|contract|security|test-gap> — <一言>
```

`found-by` の `pr-ai` / `pr-human` は land 実行後の PR レビューで取り逃しが発覚したときに使う（CLAUDE.md「指摘事項の扱い」参照）。`should-have:scope` は「スコープ判断で codex を省略していたのが誤りだった」ケース。

スタイル・文面レベルの指摘は記録しない。集計と層調整の提案は `/chore flow-retro` が行う。

## 5. 報告

各ステップの結果（PASS / 指摘と裁定 / verify の実行内容 / スキップした step と理由）をまとめて報告する。land の責務は commit / PR 作成の前提を整えるところまで。commit / PR 作成自体は呼び出し元のフローとユーザー指示に従う。
