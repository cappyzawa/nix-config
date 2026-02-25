---
name: worktree
description: Git worktree + tmux で並行作業セッションを起動する（Issue/PR/ブランチ対応）
disable-model-invocation: false
argument-hint: <Issue/PR URL, PR number, or branch-name> [task description]
allowed-tools: Bash
---

# Worktree 管理

Claude Code の `--worktree` フラグを活用して、並行作業セッションを tmux window として起動する。

## 前提

- tmux セッション内で実行することを想定

## 使用例

- `/worktree https://github.com/owner/repo/issues/123`
- `/worktree https://github.com/owner/repo/pull/456 をレビューして`
- `/worktree feature/new-api 認証機能を実装して`

## 手順

### 1. worktree 名を生成

$ARGUMENTS の先頭トークンから判別する:

| パターン | フォーマット | 例 |
|---|---|---|
| `github.com/.../issues/<n>` | `issue-<number>` | `issue-123` |
| `github.com/.../pull/<n>` | `pr-<number>` | `pr-456` |
| 数字のみ | `issue-<number>` | `issue-123` |
| それ以外 | `/` を `-` に置換 | `feature-new-api` |

引数がない場合はユーザーに質問する。

### 2. Worktree を準備

`claude --worktree` は `<repo>/.claude/worktrees/<name>` に worktree を作成し、ブランチ名は `worktree-<name>` となる。
ただし CLAUDE.md や .claude/ が git 未追跡の場合、新規 worktree にはこれらが含まれない。

事前に worktree を作成し、未追跡の Claude 設定ファイルをコピーする prep スクリプトを `/tmp/worktree-prep.sh` に書き出す。

```bash
cat > /tmp/worktree-prep.sh << 'PREP'
#!/bin/bash
set -euo pipefail
REPO_ROOT=$(git rev-parse --show-toplevel)
WNAME="<worktree-name>"
WORKTREE_DIR="${REPO_ROOT}/.claude/worktrees/${WNAME}"

mkdir -p "$(dirname "$WORKTREE_DIR")"
git worktree add "$WORKTREE_DIR" -b "worktree-${WNAME}" 2>/dev/null || true

# Sync Claude config files (handles both tracked and untracked)
[ -e "$REPO_ROOT/CLAUDE.md" ] && cp -f "$REPO_ROOT/CLAUDE.md" "$WORKTREE_DIR/CLAUDE.md"
[ -d "$REPO_ROOT/.claude" ] && rsync -a --exclude='worktrees' "$REPO_ROOT/.claude/" "$WORKTREE_DIR/.claude/"
PREP
chmod +x /tmp/worktree-prep.sh
```

### 3. tmux で起動

tmux window のタイトルは `<repository>/<worktree-name>` とする。
repository 名は `basename $(git rev-parse --show-toplevel)` で取得する。

初期プロンプトには `/add-dir <repo-root>` を先頭に付与し、その後に $ARGUMENTS を続ける。
これにより worktree 先でも元リポジトリのファイルに組み込みツール（Glob/Read/Grep）でアクセスできる。
`--model opus` と `--permission-mode plan` を指定する。

> [!IMPORTANT]
> **tmux send-keys と複数行プロンプト**
>
> `tmux send-keys` は文字列中の改行を Enter キーとして送信するため、複数行プロンプトを直接渡すと途中で実行されてしまう。
> 必ず一時ファイルに書き出してから `$(cat file)` で渡すこと。

```bash
# Write prompt to temp file (prepend /add-dir so built-in tools can access the original repo)
REPO_ROOT=$(git rev-parse --show-toplevel)
cat > /tmp/worktree-prompt.txt << EOF
/add-dir ${REPO_ROOT}
$ARGUMENTS
EOF

# Check tmux and launch (prep script runs first to ensure config files exist)
if tmux list-sessions 2>/dev/null; then
    tmux new-window -n "<repo>/<worktree-name>"
    tmux send-keys 'bash /tmp/worktree-prep.sh && claude --worktree <worktree-name> --model opus --permission-mode plan "$(cat /tmp/worktree-prompt.txt)"' C-m
else
    echo "Not in tmux session. Run manually:"
    echo '  bash /tmp/worktree-prep.sh && claude --worktree <worktree-name> --model opus --permission-mode plan'
fi
```

## 注意事項

- tmux セッション外で実行された場合は手動コマンドを表示
- `--worktree` はセッション終了時に変更がなければ自動削除、変更があれば確認される
- 一覧は `git worktree list` で確認可能
