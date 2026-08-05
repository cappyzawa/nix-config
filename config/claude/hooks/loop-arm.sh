#!/bin/bash
# Arm, inspect, or clear this session's Stop-hook loop. See loop-gate.sh.
#
#   loop-arm.sh '<check command>' '<完了条件を 1 行で>' [max_iterations]
#   loop-arm.sh --status
#   loop-arm.sh --clear
set -euo pipefail

# shellcheck source=lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# Must stay at least 2 below CLAUDE_CODE_STOP_HOOK_BLOCK_CAP (settings.json env):
# a full run costs MAX_ALLOWED blocked turns plus one for the cutoff message, and
# past the cap the harness ends the turn with an empty result.
MAX_ALLOWED=15
DEFAULT_MAX=10
# Must stay under the Stop hook's own `timeout` in settings.json, or the harness
# kills the hook before the oracle reports and the loop silently stops blocking.
DEFAULT_TIMEOUT=120

session_id="${CLAUDE_CODE_SESSION_ID:-}"
if [ -z "$session_id" ]; then
  echo "CLAUDE_CODE_SESSION_ID が無い。Claude Code のセッション内から実行すること。" >&2
  exit 1
fi

dir="$HOME/.claude/loops"
state="$dir/$session_id.json"

case "${1:-}" in
  --status)
    if [ -f "$state" ]; then jq . "$state"; else echo "このセッションに armed な loop は無い。"; fi
    exit 0
    ;;
  --clear)
    if [ -f "$state" ]; then
      jq -r '"解除: \(.check) (iteration \(.iteration)/\(.max_iterations))"' "$state"
      rm -f "$state"
    else
      echo "armed な loop は無い。"
    fi
    exit 0
    ;;
  '' | -h | --help)
    sed -n '2,6p' "$0" | sed 's/^# \{0,1\}//'
    exit 0
    ;;
esac

check="$1"
goal="${2:-}"
max="${3:-$DEFAULT_MAX}"

if [ -z "$goal" ]; then
  echo "完了条件 (第 2 引数) は必須。oracle が何を証明するのかを 1 行で書くこと。" >&2
  exit 1
fi

case "$max" in
  '' | *[!0-9]*) echo "max_iterations は整数で指定すること (got: $max)" >&2; exit 1 ;;
esac
# 0 would leave the loop unbounded, which just runs into the harness block cap.
if [ "$max" -lt 1 ]; then
  echo "max_iterations は 1 以上にすること (got: $max)。上限を外すとループを打ち切れない。" >&2
  exit 1
fi
if [ "$max" -gt "$MAX_ALLOWED" ]; then
  echo "max_iterations は $MAX_ALLOWED 以下にすること。これを超えると harness が" >&2
  echo "連続ブロック上限でターンを打ち切り、結果が空のまま終わる。" >&2
  exit 1
fi

# Measure the current value before arming. An oracle that already passes cannot
# drive a loop -- it means the oracle is not measuring the gap.
echo "arm 前に oracle を 1 回実行して現在値を測る: $check"
set +e
baseline_out=$(run_with_timeout "$DEFAULT_TIMEOUT" "$check" 2>&1)
baseline=$?
set -e
printf '%s\n' "$baseline_out" | tail -n 20
echo "現在値: exit $baseline"

mkdir -p "$dir"
jq -n \
  --arg check "$check" \
  --arg goal "$goal" \
  --arg cwd "$PWD" \
  --argjson max "$max" \
  --argjson timeout "$DEFAULT_TIMEOUT" \
  --argjson baseline "$baseline" \
  '{check: $check, goal: $goal, cwd: $cwd, iteration: 0, max_iterations: $max, timeout_seconds: $timeout, baseline_exit: $baseline}' \
  >"$state"

echo "armed: $state"
if [ "$baseline" -eq 0 ]; then
  echo
  echo "警告: oracle は arm 時点で既に exit 0。この oracle は gap を測れていない。"
  echo "回帰を保持する目的なら意図どおりだが、そうでなければ oracle を選び直すこと。"
fi
