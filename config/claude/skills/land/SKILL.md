---
name: land
description: 実装完了後の品質パス（verify → diff-review → codex レビュー → retro 記録）を順に実行し、commit / PR 作成に進める状態にする。非自明な変更の完了報告・commit / PR 作成の前に使う。
---

# Land

実装が揃った変更を「出せる状態」にする品質パス。いつ実行するか・どこまで走らせるかは `~/.claude/CLAUDE.md` の「実装後レビュー」と「スコープ判断」が規定する。この skill は手順を持つ。

main セッション（control plane）で実行する。subagent 内では実行しない。

## 0. 入力を揃える

`git status --short` で untracked ファイルを確認し、新規ファイルは `git add -N <path>` して diff に含める（`git diff HEAD` だけだと untracked が対象から落ちる）。

## 1. verify

`verify` skill を実行する。diff から変更 surface を分類し、surface ごとの観点で検証項目を起こして実行する手順は skill 側が持つ。

**これを先頭に置く理由**: 動かないコードをレビューに出しても、指摘が「動かないこと」に埋まる。また verify を最後に置くと、レビュー指摘の対応で入れた変更が未検証のまま残る。

- 証拠（コマンド / 期待 / 実際 / 判定）を transcript に出す。step 3 で codex に同梱する
- 実行できなかった検証は理由を残す
- 数行の typo やコメント修正を除き、この step はスキップしない（スコープ判断のゲート対象外）

## 2. diff-review

`diff-review` skill を実行する。5 観点の並列レビューと確信度での絞り込みは skill 側が持つ。

- 指摘の裁定は CLAUDE.md「指摘事項の扱い」に従う。仕様・API・依存・テスト期待値を変える修正は、契約自体の誤りとして扱いユーザーに戻す
- 適用した修正の要約を控える（step 3 で codex に同梱する）
- **修正が入ったら step 1 の該当する検証を回し直す**（レビュー対応の変更が未検証で残るのを防ぐ）
- **レビュー後に足した変更は、レビュー自体にもう一度かける。** verify を回し直すだけでは足りない。裁定で入れた修正そのものがバグを持ち込んだ実測が複数ある（fail-open 化が再試行を潰した / 分類と書き戻しの 2 修正の相互作用 / 修正バッチに no-op CSS が混入 / レビュー後に足した機能が契約違反）。**未レビューの diff を codex まで持ち込まない**
- `simplify` で代替しない。品質改善専門でバグを探さないので、この層のカバレッジが落ちる

## 3. codex レビュー

スコープ判断で codex 省略可の変更ならスキップして step 4 へ。実行する場合は codex skill の手順に従い、プロンプトに以下を同梱する:

- diff（untracked 込み）
- ユーザー要求（何を作るよう頼まれたか）と non-goals。ユーザー要求・既存挙動との乖離を観点にさせる
- step 1 の verify 結果（何を確かめ、何が確かめられていないか）
- step 2 で適用した修正の要約

指摘の裁定は CLAUDE.md「指摘事項の扱い」に従う。**指摘対応で変更が入ったら step 1 の該当する検証を回し直す。**

## 4. retro 記録

step 1〜3 で critical な問題（バグ・契約違反・セキュリティ）が見つかった場合、`~/.claude/retro/flow.md` に 1 行追記する（ファイル・ディレクトリが無ければ作る）。**追記だけで、既存行を読む必要はない**（flow.md は未処理キュー、処理済み履歴は `archive.md`。どちらも context に載せない）:

```
- <YYYY-MM-DD> repo:<repo> found-by:<verify|gate|diff-review|codex|empirical-tuning|user|pr-ai|pr-human> should-have:<verify|diff-review|codex|scope|none> kind:<bug|contract|security|test-gap> — <一言>
```

`found-by` の `pr-ai` / `pr-human` は land 実行後の PR レビューで取り逃しが発覚したときに使う（CLAUDE.md「指摘事項の扱い」参照）。`found-by:gate` は Stop hook の completion gate が捕まえたケース、`found-by:user` は使っていてユーザーが気づいたケース（PR レビューではないので `pr-human` に入れない）。`should-have:scope` は「スコープ判断で codex を省略していたのが誤りだった」ケース、`should-have:none` は既存のどの層も所有していなかったケース（層の追加・拡張が要るという信号）。

`archive.md` の既存行の判定は書き換えない（履歴なので、撤去された層を指す過去の `should-have:plan` もそのまま残す）。層の改名にともなう語彙の一括置換だけは、判定を変えないので行ってよい。

スタイル・文面レベルの指摘は記録しない。集計と層調整の提案は `/chore flow-retro` が行う。

## 5. 報告

各ステップの結果（PASS / 指摘と裁定 / verify の実行内容と確かめられなかったこと / スキップした step と理由）をまとめて報告する。land の責務は commit / PR 作成の前提を整えるところまで。commit / PR 作成自体は呼び出し元のフローとユーザー指示に従う。
