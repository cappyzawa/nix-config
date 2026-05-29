#!/bin/sh
# Drives @claude_spinner_frame so the tmux window-status "running" glyph can
# animate. Launched via `run-shell -b` from tmux.conf, so it is bound to the
# tmux server it was started from and exits once that server is gone.
#
# Single-instance is enforced via the @claude_spinner_pid option (macOS has no
# flock). A config reload (prefix+r) re-runs the launcher, but the new instance
# sees a live pid and exits, so the original loop keeps running. That means
# editing this script does NOT take effect on reload alone: kill the pid stored
# in @claude_spinner_pid (or restart the tmux server) to pick up changes.
#
# Caveat: pid reuse could make the liveness check (kill -0) misfire in rare
# cases; restarting the tmux server recovers.
#
# Note: `sleep` with a fractional argument relies on a BSD/GNU sleep (true on
# macOS); POSIX only mandates integer seconds.

self=$$
prev=$(tmux show -gv @claude_spinner_pid 2>/dev/null || true)
if [ -n "$prev" ] && kill -0 "$prev" 2>/dev/null; then
  exit 0
fi
tmux set -g @claude_spinner_pid "$self" 2>/dev/null || exit 0
trap 'tmux set -gu @claude_spinner_pid 2>/dev/null' EXIT INT TERM

# Braille spinner frames.
set -- ⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏
n=$#
i=0
check=0
running=0
was_running=0

while tmux has-session 2>/dev/null; do
  # Bail if a newer instance has taken over the lock.
  [ "$(tmux show -gv @claude_spinner_pid 2>/dev/null)" = "$self" ] || exit 0

  # Re-evaluate "is any window running?" at ~1s cadence to bound list-windows.
  if [ "$check" -le 0 ]; then
    if tmux list-windows -a -F '#{@claude_agent_status}' 2>/dev/null | grep -q '^running$'; then
      running=1
    else
      running=0
    fi
    check=7
  fi

  if [ "$running" -eq 1 ]; then
    i=$((i % n + 1))
    eval "frame=\${$i}"
    # frame is assigned via eval above; shellcheck can't track that.
    # shellcheck disable=SC2154
    tmux set -g @claude_spinner_frame "$frame" 2>/dev/null
    tmux refresh-client -S 2>/dev/null
    check=$((check - 1))
    sleep 0.15
  else
    # Drop the stale frame once, so the next running glyph starts from the
    # fallback (gear) instead of a frozen frame.
    if [ "$was_running" -eq 1 ]; then
      tmux set -gu @claude_spinner_frame 2>/dev/null
      tmux refresh-client -S 2>/dev/null
    fi
    sleep 0.3
  fi
  was_running=$running
done
