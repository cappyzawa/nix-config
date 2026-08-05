---
name: codex
description: OpenAI Codex にタスクを委譲する。コードレビュー / セカンドオピニオン / 別視点での調査に使う。
allowed-tools: Bash(codex exec -s read-only:*)
---

# Codex

Codex CLI に委譲してセカンドオピニオン・レビューを得るための skill。

自発的に呼ぶタイミングのルールは `~/.claude/CLAUDE.md` の「Codex レビュー」セクション参照。

## 起動コマンド

長文プロンプト (コードレビュー等) では **stdin 経由** で渡す:

```
codex exec -s read-only --cd <project_directory> - < <prompt-file>
```

短いプロンプトは positional argument で OK:

```
codex exec -s read-only --cd <project_directory> "<short request>"
```

- `<project_directory>` は対象プロジェクトの絶対パス。省略すると現在の作業ディレクトリ。
- `<prompt-file>` は scratchpad 配下の `codex-prompt-<task>.txt`。scratchpad が無い環境では `/tmp` に置く。
- Bash の timeout は **600000 (10 分)** に設定する。Codex は応答までに時間がかかることがある。

### なぜ stdin 経由を使うか

`"$(cat <<'EOF' ... EOF)"` で長文プロンプトを positional argument に乗せると、codex が `Reading additional input from stdin...` から進まず **10 分以上 hang** する事例があった（`|` をエスケープしたテーブルやバックティック付き code block を含む長文で再現）。symptom: PID は生きているが出力が数十バイトで停止、`ps` の argv に巨大な heredoc が見える。

stdin 経由 (`- < file`) に切り替えると同じプロンプトが **20-30 秒** で完走する。`-` は「prompt を stdin から読む」を明示するための positional。

### 手順 (長文の場合)

1. Write tool でプロンプトを `<prompt-file>` に書く
2. `codex exec -s read-only --cd <dir> - < <prompt-file>` を実行
   - `run_in_background: true` + 出力先 (`tee` または harness の output file) で監視するのを推奨
3. 完了後に出力ファイルを Read で読む

## プロンプトのルール

Codex に渡す依頼文には必ず以下のニュアンスを含める:

> 「確認や質問は不要。具体的な提案・修正案・コード例を能動的に出してほしい」

これを省くと Codex が確認や前提質問を返してきて往復が増える。

## 主な用途と例

### コードレビュー（commit 前）

```bash
# Step 1: prompt を file に書く (diff も同じ file に貼る場合は大きいので必ず stdin 経由)
# Step 2:
codex exec -s read-only --cd <dir> - < <prompt-file>
```

内容例:
> 以下の diff をレビューしてほしい。読んで見つかる誤りのレビュー (diff-review) は実施済みなので主目的にしなくてよいが、correctness / security / data loss に関わる問題は実施済みの観点に見えても必ず指摘してほしい。観点は (1) 同梱したユーザー要求・合格基準との乖離 (2) 設計判断の誤り (3) エッジケースの見落とし (4) テストの過不足。確認や質問は不要、具体的な修正案とコード例を能動的に出してほしい。

プロンプトに含めるもの:

- **diff**: レビュー前に `git status --short` を確認し、untracked の新規ファイルがあれば `git add -N <path>` してから diff を取る（`git diff HEAD` だけだと untracked が対象から落ちる）
- **ユーザー要求・non-goals・合格基準**（§証明の形を決める で作った check）。codex は会話を見ていないので、これが無いと「要求との乖離」を判定できない
- **diff-review で適用した修正の要約**（実施した場合）

diff-review を通していない diff（スコープ判断で省略した場合等）では、従来どおり (1) バグ・エッジケースの見落とし (2) テストの過不足 (3) 命名・抽象化の妥当性 を観点にする。

### バグ調査のセカンドオピニオン（修正 2 回失敗後）

短ければ positional でも可:

```
codex exec -s read-only --cd <dir> "<バグの症状><試した修正案 1><試した修正案 2> について、原因の仮説と次に試すべき修正方針を能動的に提案してほしい。確認や質問は不要。"
```

長い stack trace やログを含める場合は stdin 経由に切り替える。

### 設計判断・ベストプラクティス

```
codex exec -s read-only --cd <dir> "<質問内容>。確認や質問は不要、具体的な提案を能動的に出してほしい。"
```

## 手順

1. `~/.claude/CLAUDE.md` の「Codex レビュー」トリガー、またはユーザー要求に従って、codex に委譲する対象を特定する
2. プロンプトに「確認や質問は不要。具体的な提案・修正案・コード例を能動的に出してほしい」を必ず付ける
3. 長文 (diff / コード片を含む) は Write tool で `<prompt-file>` に書き、stdin redirect で渡す。短ければ positional でも可
4. `codex exec -s read-only --cd <dir>` を Bash timeout 600000 で実行する
5. Codex の指摘を要約してユーザーに報告する。即時対応する指摘と見送る指摘を分けて提示する

## 失敗時の切り分け

- 出力が数十バイトで止まっている / 5 分以上動かない → positional argument で渡していないか確認。長文なら stdin redirect に切り替える
- `Reading additional input from stdin...` が出力に見える → codex が stdin 待ち。`-` を positional に指定 + stdin から prompt を流す
