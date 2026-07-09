# memory

## 目的

auto memory に自然に溜まった知識のうち、リポジトリにコミットすべきものを正式な文書（AGENTS.md / CLAUDE.md / docs/ / .claude/rules/）へ昇格させる。memory は個人の作業記憶、リポジトリの文書はチームの共有知識 — この境界を定期的に整理し、MEMORY.md の index を肥大させない。

## 発見

- 現在のプロジェクトの auto memory ディレクトリ（システムプロンプトに記載）を読む
- MEMORY.md の index と各 memory ファイルのうち、frontmatter の metadata に `triage` キーが無いものが未処理
- 昇格 PR が merge 済みのエントリ（`triage: promoted` かつ PR が merged）があれば、この周回で memory ファイルと MEMORY.md の index 行を削除する（merge が削除の承認を兼ねる）
- 未処理ゼロかつ削除対象ゼロなら仕事なし

## 実行（1 件ごと）

1. 鮮度と重複を確認する。その知識が既に (a) docs / rules / AGENTS.md に記載済み、または (b) 自動化（scaffold・lint・codegen・CI）で強制済みかを現在のコードベースで確かめる。該当したら昇格せず削除提案に回す
2. 3 分類する。metadata の `type` を目安にしつつ、最終判断は内容で行う:
   - **昇格**: プロジェクト・ドメインの知識で、他の人間や agent にも有用なもの（`project` / `reference` 型が中心）。行き先 — 規約・アーキテクチャは AGENTS.md / CLAUDE.md、ドメイン知識・用語は docs/、ファイル局所のルールは .claude/rules/（`paths:` でスコープ）
   - **memory に残す**: このユーザー個人の好み・作業スタイルに関するもの（`user` / `feedback` 型が中心）。私的な知識はリポジトリに出さない
   - **削除提案**: 陳腐化した・誤りと判明した・上記 1 で重複と判明したもの
   - 型と内容が食い違う場合（例: feedback 型だが実質リポジトリ規約）は内容を優先する。公開リポジトリへの昇格で迷う場合は要人間として報告に含める
3. 昇格する場合、既存ドキュメントの文体・構成・言語に合わせて書く

## 検証

- lint（markdownlint 等）がプロジェクトに設定されていれば通す
- 最終検証は人間の PR レビュー。したがって昇格の変更は必ず draft PR で出す（公開リポジトリでは PR title / body は英語）

## 記録

- 処理したエントリの frontmatter metadata に triage 結果を注記する: `triage: promoted <PR URL>` / `triage: keep <日付>` / `triage: delete-proposed <理由>`
- ループ内でエントリを直接削除しない。削除が確定するのは、昇格 PR の merge 後（発見の項）または人間の明示指示のみ
- memory ファイルの内容を書き換えるのは metadata の注記のみ。本文は変更しない

## 上限

- 1 回の実行で 3 件まで
