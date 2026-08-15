---
name: worktree
description: Git worktree + herdr で並行作業セッションを起動する（Issue/PR/ブランチ対応）
disable-model-invocation: false
argument-hint: <Issue/PR URL, Issue number, or branch-name> [--model <model>] [--plan] [task description]
allowed-tools: Bash
---

# Worktree 管理

Claude Code の `--worktree` フラグを活用して、並行作業セッションを herdr の
worktree-backed workspace として起動する。workspace は sidebar で repo 配下に
グループ化され、エージェント状態が repo 単位に集約される。

## 前提

- herdr がインストールされていること。無ければ起動せず「nix-config で `make switch`」を案内して終了する
- herdr server は前提にしない。動いていなければこの skill が起動する（fallback 分岐は持たない）

## 使用例

- `/worktree https://github.com/owner/repo/issues/123`
- `/worktree https://github.com/owner/repo/pull/456 をレビューして`
- `/worktree feature/new-api 認証機能を実装して`
- `/worktree feature/new-api --model sonnet 認証機能を実装して`
- `/worktree feature/new-api --plan 設計を考えて`

## 手順

以降の shell snippet 中のプレースホルダ `<worktree-name>` は手順 1 で決めた WNAME、
`<repo-root>` は main checkout の絶対パスで、実行前に文字列置換すること。

`<repo-root>` は次で解決する。`git rev-parse --show-toplevel` は worktree 内から
呼ばれると worktree 自身を返し、入れ子の worktree 作成と worktree の branch からの
派生を招く。common-dir 経由なら常に main checkout に解決され、herdr create の
`--cwd` にこれを渡すことで新 branch は main checkout の HEAD から派生する（実測済み）。

```bash
REPO_ROOT=$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")
```

### 1. worktree 名を生成

$ARGUMENTS の先頭トークンから判別する:

| パターン | フォーマット | 例 |
|---|---|---|
| `github.com/.../issues/<n>` | `issue-<number>` | `issue-123` |
| `github.com/.../pull/<n>` | `pr-<number>` | `pr-456` |
| 数字のみ | `issue-<number>` | `issue-123` |
| それ以外 | `/` を `-` に置換 | `feature-new-api` |

生成した名前はさらに `[A-Za-z0-9._-]` 以外の文字を `-` に置換する
（名前は branch 名・パス・launcher script に埋め込まれるため、ここで安全な文字集合に閉じる）。

引数がない場合はユーザーに質問する。

### 1.5. 引数を解析

`$ARGUMENTS` から以下を抽出する:

- `--model <value>`: モデルを指定。指定がなければ `--model` 自体を付与しない（claude のデフォルトに委ねる）。
  - **モデル値は絶対に変換・補完しないこと**。ユーザーが指定した値をそのまま使う。
- `--plan`: plan mode フラグ。permission mode はデフォルトで `auto`、`--plan` 指定時のみ `plan` に上書きする。

```bash
MODEL=""
PERM_MODE="auto"
ARGS="$ARGUMENTS"

# Extract --model value as-is (do NOT normalize or alias the value)
if echo "$ARGS" | grep -q -- '--model '; then
  MODEL=$(echo "$ARGS" | sed 's/.*--model \([^ ]*\).*/\1/')
  ARGS=$(echo "$ARGS" | sed 's/--model [^ ]*//' | xargs)
fi

# Extract --plan flag (overrides the default auto permission mode)
if echo "$ARGS" | grep -q -- '--plan'; then
  PERM_MODE="plan"
  ARGS=$(echo "$ARGS" | sed 's/--plan//' | xargs)
fi
```

以降の手順では `$ARGS` をプロンプトとして使う。`$MODEL` と `$PERM_MODE` は
手順 3 の launcher 生成時に `printf %q` 経由で焼き込む。

### 2. 実行環境と作業ディレクトリを整える

herdr が無ければインストールを案内して止まり、server が無ければ起動する。
一時ファイル（prep / prompt / launcher）は `mktemp -d` の per-run ディレクトリに
まとめる。固定パスだと連続・並行起動（別 repo の同名 issue を含む）で後発が先発の
内容を上書きし、先に開いた workspace が別のプロンプトで起動する。

```bash
command -v herdr > /dev/null || { echo "herdr is not installed. Run: make switch (in nix-config)" >&2; exit 1; }
if ! herdr status server 2>/dev/null | grep -q "status: running"; then
  nohup herdr server > /dev/null 2>&1 &
  for _ in $(seq 1 20); do
    herdr status server 2>/dev/null | grep -q "status: running" && break
    /bin/sleep 0.5
  done
fi

RUN_DIR=$(mktemp -d "${TMPDIR:-/tmp}/worktree-<worktree-name>.XXXXXX")
```

prep スクリプトを `$RUN_DIR/prep.sh` に書き出す。worktree そのものは手順 3 で
herdr が作るが、`claude --worktree` の worktree
（`<repo-root>/.claude/worktrees/<worktree-name>`、ブランチ `worktree-<worktree-name>`）
には CLAUDE.md や .claude/ が git 未追跡の場合それらが含まれないため、コピーで補う。

REPO_ROOT は生成時に絶対パスで焼き込む。herdr が開く pane の cwd は worktree 内なので、
実行時に `git rev-parse --show-toplevel` で解決すると worktree 自身を指してしまう。

```bash
cat > "$RUN_DIR/prep.sh" << 'PREP'
#!/bin/bash
set -euo pipefail
REPO_ROOT="<repo-root>"
WORKTREE_DIR="${REPO_ROOT}/.claude/worktrees/<worktree-name>"

# Sync Claude config files (handles both tracked and untracked)
[ -e "$REPO_ROOT/CLAUDE.md" ] && cp -f "$REPO_ROOT/CLAUDE.md" "$WORKTREE_DIR/CLAUDE.md"
[ -d "$REPO_ROOT/.claude" ] && rsync -a --exclude='worktrees' "$REPO_ROOT/.claude/" "$WORKTREE_DIR/.claude/"

# Symlink per-directory CLAUDE.local.md into the worktree. These are untracked
# (globally gitignored) so git worktree does not carry them, and they are
# discovered under cwd only, so nesting under the repo does not help either.
# Symlink instead of copy: copies go stale as soon as the main checkout edits
# the file. Root CLAUDE.local.md is excluded (-mindepth 2) because the
# worktree lives inside the repo and directory walk-up already loads it.
(cd "$REPO_ROOT" && find . -mindepth 2 -name 'CLAUDE.local.md' -not -path './.claude/worktrees/*' -print0) |
  while IFS= read -r -d '' f; do
    mkdir -p "$WORKTREE_DIR/$(dirname "$f")"
    ln -sfn "$REPO_ROOT/${f#./}" "$WORKTREE_DIR/${f#./}"
  done
PREP
chmod +x "$RUN_DIR/prep.sh"
```

### 3. herdr で起動

worktree の作成は herdr に任せる（workspace に repo への所属情報が付き、sidebar で
グループ化される）。label に repo 名を含めないのは、repo の判別をこのグループ化が
担うため（旧版の tmux window 命名 `<repo>/<worktree-name>` の引き受け先)。
同名 worktree が既にあるときは create が失敗するので open で adopt する。

prep は fresh create のときだけ launcher に含める。adopt した既存 worktree で
prep を回すと、worktree 側で編集された CLAUDE.md / .claude/ を main checkout の
内容で上書きして作業内容を失う。

pane には launcher script のパスだけを渡す。プロンプト・モデル値・複数行の
コマンドを pane 注入文字列に直接埋め込むと、quoting の破れや改行の Enter 化で
壊れる（quoting はすべて launcher 生成時に `printf %q` で解決しておく）。

launcher は `cd <repo-root>` から始める。pane の cwd は worktree 内で、
`claude --worktree` を worktree 内から実行したときの解決先は保証されていないため、
tmux 時代と同じ「main checkout から起動して claude が worktree へ cd する」経路に
固定する（セッション終了時の worktree 自動削除もこの経路の挙動）。

```bash
# Write prompt to temp file (use $ARGS with --model / --plan stripped)
cat > "$RUN_DIR/prompt.txt" << EOF
$ARGS
EOF

FRESH=1
OUT=$(herdr worktree create --cwd "<repo-root>" \
  --path "<repo-root>/.claude/worktrees/<worktree-name>" \
  --branch "worktree-<worktree-name>" --label "<worktree-name>" --no-focus) || {
  FRESH=0
  OUT=$(herdr worktree open --cwd "<repo-root>" \
    --path "<repo-root>/.claude/worktrees/<worktree-name>" \
    --label "<worktree-name>" --no-focus)
}
# Both failed (errors already printed to stderr by herdr). Without this
# guard, jq silently emits "" and pane run dies with a misleading
# pane_not_found.
PANE=$(printf '%s' "$OUT" | jq -r '.result.root_pane.pane_id // empty')
if [ -z "$PANE" ]; then
    echo "herdr worktree create/open failed; see errors above" >&2
    exit 1
fi

{
  echo '#!/bin/bash'
  echo 'set -euo pipefail'
  printf 'cd %q\n' "<repo-root>"
  [ "$FRESH" = 1 ] && printf 'bash %q\n' "$RUN_DIR/prep.sh"
  printf 'exec claude --worktree %q ' "<worktree-name>"
  [ -n "$MODEL" ] && printf -- '--model %q ' "$MODEL"
  printf -- '--permission-mode %q ' "$PERM_MODE"
  printf '"$(cat %q)"\n' "$RUN_DIR/prompt.txt"
} > "$RUN_DIR/launch.sh"

herdr pane run "$PANE" "bash $RUN_DIR/launch.sh"
```

## 注意事項

- `--worktree` はセッション終了時に変更がなければ自動削除、変更があれば確認される
- 自動削除後は workspace の cwd が消えるため、`herdr workspace close <workspace-id>` でその workspace を閉じる
- 一覧は `herdr worktree list --cwd <repo-root>`（git 側は `git worktree list`）で確認可能
