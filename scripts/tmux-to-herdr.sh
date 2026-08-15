#!/usr/bin/env bash
# One-shot migration: recreate every window of a tmux session as a herdr
# workspace. Meant to run once per host when switching the multiplexer.
#
#   DRY_RUN=1 ./scripts/tmux-to-herdr.sh [session]   # print the plan only
#   ./scripts/tmux-to-herdr.sh [session]             # default session: zzz
#
# Behavior, shaped by the first migration:
# - A window whose cwd is a linked git worktree is opened with
#   `herdr worktree open`, so the workspace groups under its repo in the
#   sidebar (the repo workspace is created first when missing).
# - A window whose cwd no longer exists is skipped: herdr silently falls
#   back to $HOME and the workspace ends up orphaned and dangerous to
#   resume in.
# - Panes running Claude Code (pane_current_command is the version string,
#   e.g. "2.1.223") get a resume command STAGED (typed, Enter not pressed)
#   so nothing double-runs while the tmux twin is alive. When one cwd has
#   several claude panes, `claude --continue` cannot tell them apart, so
#   those get the interactive `claude --resume` picker instead.
set -euo pipefail

SESSION="${1:-zzz}"
DRY_RUN="${DRY_RUN:-0}"

plan() { echo "PLAN: $*"; }

for dep in tmux herdr jq; do
  command -v "$dep" > /dev/null || { echo "missing dependency: $dep" >&2; exit 1; }
done
tmux has-session -t "$SESSION" 2>/dev/null || { echo "no tmux session: $SESSION" >&2; exit 1; }
if [ "$DRY_RUN" != 1 ]; then
  herdr status server 2>/dev/null | grep -q "status: running" || { echo "herdr server not running (open a herdr terminal first)" >&2; exit 1; }
fi

INV=$(mktemp)
trap 'rm -f "$INV" "$CWDCOUNT"' EXIT
tmux list-panes -s -t "$SESSION" -F '#{window_index}	#{pane_index}	#{pane_current_command}	#{pane_current_path}' > "$INV"

# claude pane count per cwd decides --continue vs --resume
CWDCOUNT=$(mktemp)
awk -F'\t' '$3 ~ /^[0-9]+(\.[0-9]+)+$/ {print $4}' "$INV" | sort | uniq -c | sed 's/^ *//' > "$CWDCOUNT"

stage_cmd_for() {
  local cwd="$1" n
  n=$(awk -v d="$cwd" '$2 == d {print $1}' "$CWDCOUNT")
  if [ "${n:-0}" -gt 1 ]; then echo "claude --resume"; else echo "claude --continue"; fi
}

# Prints the root pane id of the created/adopted workspace, "" on dry-run
open_workspace() {
  local kind="$1" cwd="$2" label="$3" out
  case "$kind" in
    worktree)
      local root parent
      root=$(dirname "$(git -C "$cwd" rev-parse --path-format=absolute --git-common-dir)")
      parent=$(herdr worktree list --cwd "$root" 2>/dev/null |
        jq -r '.result.worktrees[] | select(.is_linked_worktree | not) | .open_workspace_id // empty' | head -1)
      if [ -z "$parent" ]; then
        if [ "$DRY_RUN" = 1 ]; then
          plan "workspace create (repo) --cwd $root --label $(basename "$root")" >&2
        else
          herdr workspace create --cwd "$root" --label "$(basename "$root")" --no-focus > /dev/null
        fi
      fi
      if [ "$DRY_RUN" = 1 ]; then
        plan "worktree open --cwd $root --path $cwd --label $label" >&2
        return 0
      fi
      out=$(herdr worktree open --cwd "$root" --path "$cwd" --label "$label" --no-focus)
      ;;
    *)
      if [ "$DRY_RUN" = 1 ]; then
        plan "workspace create --cwd $cwd --label $label" >&2
        return 0
      fi
      out=$(herdr workspace create --cwd "$cwd" --label "$label" --no-focus)
      ;;
  esac
  printf '%s' "$out" | jq -r '.result.root_pane.pane_id // empty'
}

tmux list-windows -t "$SESSION" -F '#{window_index}	#{window_name}' |
while IFS=$'\t' read -r widx wname; do
  root_pane=""
  first=1
  while IFS=$'\t' read -r _ pidx pcmd pcwd; do
    if [ ! -d "$pcwd" ]; then
      echo "SKIP zzz:${widx}.${pidx} (${wname}): cwd gone: $pcwd" >&2
      continue
    fi
    if [ "$first" = 1 ]; then
      first=0
      kind=plain
      if git -C "$pcwd" rev-parse --git-dir > /dev/null 2>&1; then
        gitdir=$(git -C "$pcwd" rev-parse --path-format=absolute --absolute-git-dir)
        common=$(git -C "$pcwd" rev-parse --path-format=absolute --git-common-dir)
        if [ "$gitdir" != "$common" ]; then kind=worktree; else kind=repo; fi
      fi
      # grouped worktrees show the repo via the sidebar group, so the
      # label drops the old "<repo>/" window-name prefix
      label="$wname"
      [ "$kind" = worktree ] && label="${wname##*/}"
      pane_id=$(open_workspace "$kind" "$pcwd" "$label")
      root_pane="$pane_id"
    else
      if [ "$DRY_RUN" = 1 ]; then
        plan "pane split (window $wname) --direction down --cwd $pcwd"
        pane_id=""
      elif [ -z "$root_pane" ]; then
        echo "SKIP zzz:${widx}.${pidx} (${wname}): no root pane" >&2
        continue
      else
        out=$(herdr pane split "$root_pane" --direction down --cwd "$pcwd" --no-focus)
        pane_id=$(printf '%s' "$out" | jq -r '.result.pane.pane_id // .result.root_pane.pane_id // empty')
      fi
    fi
    if printf '%s' "$pcmd" | grep -Eq '^[0-9]+(\.[0-9]+)+$'; then
      cmd=$(stage_cmd_for "$pcwd")
      if [ "$DRY_RUN" = 1 ]; then
        plan "stage in ${wname}.${pidx}: $cmd"
      elif [ -n "$pane_id" ]; then
        herdr pane send-text "$pane_id" "$cmd" > /dev/null
        echo "staged ${wname}.${pidx} -> ${pane_id}: $cmd"
      fi
    fi
  done < <(awk -F'\t' -v w="$widx" '$1 == w' "$INV")
done
