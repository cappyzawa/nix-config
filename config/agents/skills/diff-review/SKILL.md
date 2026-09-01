---
name: diff-review
description: 作業ツリーの diff を複数の観点で並列レビューし、確信度で絞った指摘を返す。commit / PR の前、land skill のレビュー step で使う。
---

# Diff Review

作業ツリーの diff（PR ではなく、まだ commit していない変更）を並列レビューする。**読むことで見つかる誤り**を担当する層で、動くことの証明は `verify` skill、別モデルの視点は独立 reviewer が持つ。

main セッション（control plane）で実行する。subagent 内では実行しない。指摘の裁定と修正の適用は main の責務。

手順は順に実行する。**最初に todo list を作る**（step が飛ぶと、どの観点が走っていないかが報告から消える）。

## agent の起動

各 step は独立 context の subagent に投げ、model は tier で選ぶ。**tier を指定しないと session のモデルを継承する**ので、上位モデルのセッションではレビュアー 5 本がそれになる。

| harness | 起動 | fast tier | balanced tier |
|---|---|---|---|
| Claude Code | Agent tool を `subagent_type: "general-purpose"` と `model` 指定で呼ぶ。結論は末尾の `SendMessage({to: "main"})` で返させる | `haiku` | `sonnet` |
| Codex | `review-fast` / `review-balanced` role を spawn する。tier と `sandbox_mode = "read-only"` は role 側に pin してある | `review-fast` | `review-balanced` |

harness が agent 名を受け取る場合は、グローバル instructions の §サブエージェントへの委譲 に従い `<観点キー>-<実効model>-<effort>` にする（例: `review-rules-sonnet-inh`）。Codex は呼び出し側から名前を渡せず presentation 用の nickname が付くだけなので、この形式が効くのは Claude Code だけ。

**Codex で tier を prompt に書いても効かない。** spawn 呼び出しでの model 指定は `features.multi_agent_v2.expose_spawn_agent_model_overrides` を立てたときだけ露出し、それが無いと subagent は session の model を黙って継承する（エラーにならないので気づけない）。tier と sandbox を確実に効かせる経路が role 定義なので、Codex 側は role を spawn する。

**並列本数は harness の上限を先に確認し、収まらない分は wave に分けて回す。** Codex は `~/.codex/config.toml` の `agents.max_concurrent_threads_per_session` が同時に開ける spawned agent thread 数の上限（primary は数えない）。step 4 は 5 本で固定だが、**step 5 は指摘数ぶんなので上限に収まる保証が無い**。上限に依存しない形で回すこと。

## 1. 対象を確定し、レビューする価値があるか判定する

```
git status --short
git add -N <新規ファイル>     # untracked を diff に含める
git diff HEAD --stat
```

次のいずれかなら**進まずに理由を報告して終わる**: diff が空 / 機械的な変更のみ（lint・format・リネーム・生成物の再生成）/ このセッションで同じ diff を既にレビューした。

## 2. 規約ファイルの場所を集める

fast tier の agent（`review-scan`）に、**内容ではなくパスだけ**を列挙させる: リポジトリ root の `AGENTS.md` / `CLAUDE.md`、変更されたファイルのディレクトリにある同名ファイル、変更ファイルに対応する言語コーディング規約（Claude Code は `.claude/rules/*.md` と `~/.claude/rules/*.md` のうち `paths:` frontmatter が一致するもの、Codex は `~/.agents/rules/<language>.md`）。**言語コーディング規約はグローバル側にあり、これを外すと `review-rules` が言語プラクティス準拠を見ない。**

## 3. 変更の要約を作る

fast tier の agent（`review-summary`）に diff を読ませ、**何を変えた変更なのか**を数行で返させる。step 4 の各観点に渡す。5 本が同じ地図を各自で引き直すのを防ぐのが目的で、判定材料ではない。

## 4. 5 つの観点で並列レビューする

5 つの agent を balanced tier で**まとめて並列起動する**（Claude Code なら単一メッセージから）。各 agent に diff、step 2 のパス一覧、step 3 の要約、ユーザー要求と non-goals を渡す。

| 観点キー | 観点 |
|---|---|
| `review-rules` | 規約遵守。step 2 のファイルを読み、diff が違反していないか。**規約はコードを書く側への指示なので、レビュー時には当てはまらない項目がある**ことを前提にする |
| `review-bugs` | diff 本体だけを読んで明らかなバグを探す。周辺コードまで読み広げない。大きいものに絞り、nitpick は出さない。誤検出らしいものは出さない |
| `review-history` | 変更箇所の `git log -p` / `git blame` と、**同じファイルに触った過去 PR のレビューコメント**（下記手順）を読み、当時の指摘が今回にも当てはまらないか。一度直した問題の再導入、意図があって書かれた形の破壊 |
| `review-deletion` | **diff で消えた記述・分岐・検証が運んでいた義務**に引き受け先があるか。ユーザー要求のうち diff に現れていないものが無いか。失われた義務は不在なので diff に現れず、他の観点では出ない |
| `review-intent` | 変更されたファイル内のコメント・型・命名が述べている制約と、diff の整合。コメントが嘘になっていないか |

`review-history` に渡す過去 PR の手繰り方。**現在の変更に PR は無くてよい**（読むのは同じファイルに触った過去のマージ済み PR）:

```bash
# squash merge の subject に載る (#N) から番号を得る。gh pr list は path で絞れない
git log --format='%s%n%b' -50 -- <変更されたパス> | grep -oE '#[0-9]+' | tr -d '#' | sort -un |
while read -r n; do
  gh pr view "$n" --json title,reviews,comments
  gh api "repos/{owner}/{repo}/pulls/$n/comments"   # inline コメントは pr view に出ない
done
```

番号が取れない（直 commit の履歴）か、取れても全部 0 件のリポジトリはある。そのときは**「過去 PR のコメントは無い」と明示させる**（黙って 0 件にすると、観点が走ったのか判別できない）。

各 agent には指摘ごとに「ファイル:行 / 何が問題か / なぜ挙げたか（規約遵守・バグ・履歴のどれか）」を返させる。**根拠を引用できないものは指摘にしない。**

**文面のみの diff**（ドキュメント・規約・プロンプト）では `review-bugs` と `review-history` を省いてよい。残る 3 つ（規約遵守 / 削除された義務 / コメントの整合）は文面 diff でこそ効くので省かない。この skill 全体をスキップはしない。

## 5. 確信度で絞る

指摘ごとに balanced tier の agent（`score-<観点キー>`）を並列起動し、diff・指摘文・step 2 のパス一覧を渡して 0〜100 で採点させる。ルーブリックはそのまま渡す:

- **0**: 軽く検証すれば崩れる誤検出、または変更前から存在する問題
- **25**: 実在するかもしれないが検証できていない。規約由来なら該当規約に明示されていない
- **50**: 実在は確認したが、nitpick か稀なケース。この diff の中では重要度が低い
- **75**: 検証済みで、実際に踏む可能性が高い。機能に直接影響する、または規約に明記されている
- **100**: 確実。証拠が直接裏付けている

**80 未満は捨てる。** 規約由来の指摘は、その規約が本当にそれを述べているかを採点側で読み直させる。

## 誤検出として捨てるもの

- 変更前から存在する問題、diff で触っていない行の問題
- linter / typechecker / コンパイラ / テストが捕まえるもの（**この層は動かさない**。実行は `verify` skill が済ませている）
- senior engineer が指摘しない粒度の様式論
- 規約に触れるが、コード側で明示的に抑制されているもの（lint ignore コメント等）
- 意図的と読める挙動変更、変更の主目的に付随する変更
- テストカバレッジ不足・ドキュメント不足のような一般論（規約が明示的に要求している場合を除く）

## 6. 報告と適用

指摘を確信度の降順で並べ、`ファイル:行 / 指摘 / 根拠 / 確信度` の形で報告する。0 件なら 0 件と述べ、**5 観点それぞれについて何を見たかを 1 行ずつ添える**（どの観点が実際に走ったかが分からないと、0 件が「異常なし」なのか「観点が抜けた」のか読み手に区別できない）。

裁定と修正はグローバル instructions の「指摘事項の扱い」に従う。**修正を適用したら `verify` の該当項目を回し直す**（レビュー対応の変更が未検証で残るのを防ぐ）。
