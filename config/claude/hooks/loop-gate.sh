#!/bin/bash
# Stop hook: keeps the turn going until this session's oracle command exits 0.
#
# The oracle is executed here rather than judged from the transcript, so "it
# passed" can never be self-reported. That is the reason this exists instead of
# /goal, whose evaluator cannot call tools and can only read what the model
# already wrote into the conversation.
#
# Armed by loop-arm.sh, which writes ~/.claude/loops/<session_id>.json.
#
# Past CLAUDE_CODE_STOP_HOOK_BLOCK_CAP consecutive blocks (settings.json env,
# default 8) the harness overrides the hook and ends the turn with an empty
# result -- worse than no loop. The counter rises once per blocked turn, not per
# blocking hook, so co-firing Stop hooks do not multiply it; a full run costs
# max_iterations blocked turns plus one for the cutoff message. So the cap must
# exceed loop-arm.sh's MAX_ALLOWED + 1.
set -uo pipefail

# shellcheck source=lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

input=$(cat)
session_id=$(jq -r '.session_id // ""' <<<"$input" 2>/dev/null || true)
[ -n "$session_id" ] || exit 0

state="$HOME/.claude/loops/$session_id.json"
[ -f "$state" ] || exit 0

# A loop that cannot be disarmed would block every turn until the harness cap
# ends the turn with an empty result, so an unwritable state directory degrades
# to no loop at all. systemMessage says so without blocking.
if [ ! -w "$(dirname "$state")" ]; then
  jq -n --arg m "loop: state ディレクトリに書き込めないためループを停止した（解除も iteration 更新もできない）" '{systemMessage: $m}'
  exit 0
fi

# Block once with an explanation, after disarming. A corrupt or impossible loop
# that keeps blocking cannot be recovered from inside the session.
disarm_and_say() {
  rm -f "$state" 2>/dev/null || true
  jq -n --arg r "$1" '{decision: "block", reason: $r}'
  exit 0
}

if ! jq -e . "$state" >/dev/null 2>&1; then
  disarm_and_say "loop state ($state) が壊れている。ループを解除した。続けるなら loop-arm.sh で arm し直すこと。"
fi

check=$(jq -r '.check // ""' "$state")
goal=$(jq -r '.goal // ""' "$state")
cwd=$(jq -r '.cwd // ""' "$state")
iteration=$(jq -r '.iteration // 0' "$state")
max=$(jq -r '.max_iterations // 10' "$state")
timeout_s=$(jq -r '.timeout_seconds // 300' "$state")

[ -n "$check" ] || disarm_and_say "loop state に check が無い。ループを解除した。"

for field in iteration max timeout_s; do
  case "${!field}" in
    '' | *[!0-9]*) disarm_and_say "loop state の $field が数値でない (${!field})。ループを解除した。" ;;
  esac
done

# No "0 means unlimited" escape: an unbounded loop just runs into the harness
# block cap, which ends the turn with an empty result.
[ "$max" -ge 1 ] || disarm_and_say "loop state の max_iterations が ${max}。1 以上でなければループを打ち切れない。解除した。"
[ "$timeout_s" -ge 1 ] || disarm_and_say "loop state の timeout_seconds が ${timeout_s}。1 以上にすること。解除した。"

run_dir="${cwd:-$PWD}"
[ -d "$run_dir" ] || disarm_and_say "loop state の cwd ($run_dir) が存在しない。ループを解除した。"

if [ "$iteration" -ge "$max" ]; then
  disarm_and_say "$(
    printf 'ループを max_iterations (%s) で打ち切り、解除した（state ファイルは削除済み。以降このターンは素通りする）。oracle は未達のまま。\n\n完了条件: %s\noracle: %s\n\n何が残っているか、なぜ通らなかったかを述べて終われ。通ったことにしないこと。' \
      "$max" "$goal" "$check"
  )"
fi

output=$(cd "$run_dir" && run_with_timeout "$timeout_s" "$check" 2>&1)
status=$?

if [ "$status" -eq 0 ]; then
  rm -f "$state"
  jq -n --arg m "loop: oracle PASS ($check) — iteration $iteration で解除" '{systemMessage: $m}'
  exit 0
fi

# An oracle that stopped being runnable is no longer measuring anything, so it
# would spend every remaining iteration on the same error.
case "$status" in
  126 | 127)
    disarm_and_say "$(
      printf 'oracle (%s) が実行できない (exit %s)。測れないものは停止条件にならないのでループを解除した。\n\n--- 出力 ---\n%s\n---\n\n実行可能な oracle を選んで loop-arm.sh で arm し直すか、なぜ arm できないかを述べて終われ。' \
        "$check" "$status" "$(printf '%s\n' "$output" | tail -n 10)"
    )"
    ;;
esac

# Bail if the bump cannot be persisted. Continuing would re-read the same
# iteration every turn, never reach the cutoff, and block until the harness cap
# ends the turn with an empty result.
next=$((iteration + 1))
tmp="$state.tmp.$$"
if ! (jq --argjson i "$next" '.iteration = $i' "$state" >"$tmp" && mv "$tmp" "$state") 2>/dev/null; then
  rm -f "$tmp"
  disarm_and_say "loop state ($state) の iteration を更新できなかった。打ち切りが機能しないのでループを解除した。oracle は未達（exit ${status}）。ディスク容量と権限を確認すること。"
fi

tail_out=$(printf '%s\n' "$output" | tail -n 40 | cut -c1-500)
[ "$status" -eq 142 ] && status="142 (timeout ${timeout_s}s)"

reason=$(
  # shellcheck disable=SC2016  # the backticks are markdown for the model to read
  printf 'ループ継続 (iteration %s/%s)。\n\n完了条件: %s\noracle: %s\n結果: exit %s\n\n--- 出力 (末尾 40 行) ---\n%s\n---\n\nこの oracle が exit 0 になるまで作業を続けろ。**oracle 自体を書き換えて通すことは禁止。** oracle が誤っていると判断したら、書き換えずに `loop-arm.sh --clear` で解除し、なぜ誤りかを述べてユーザーに戻せ。\n' \
    "$next" "$max" "$goal" "$check" "$status" "$tail_out"
)

jq -n --arg r "$reason" --arg m "loop iteration $next/$max — oracle 未達" \
  '{decision: "block", reason: $r, systemMessage: $m}'
