#!/bin/bash
# meeting-opener.sh - Automatically open meeting URLs before events start
#
# Checks macOS Calendar events via icalBuddy and opens Zoom/Meet/Teams/Webex
# URLs 1 minute before the event starts. Tracks opened events to avoid duplicates.

set -euo pipefail

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/meeting-opener"
OPENED_LOG="$STATE_DIR/opened.log"
EVENT_MARKER='%%EVENT%%'

mkdir -p "$STATE_DIR"
touch "$OPENED_LOG"

# Clean up log entries older than 24 hours
cleanup_old_entries() {
  local cutoff
  cutoff=$(date -v-24H +%s 2>/dev/null || date -d '24 hours ago' +%s)
  local tmp
  tmp=$(mktemp)
  while IFS='|' read -r ts rest; do
    if [[ -n "$ts" ]] && (( ts > cutoff )); then
      echo "${ts}|${rest}"
    fi
  done < "$OPENED_LOG" > "$tmp"
  mv "$tmp" "$OPENED_LOG"
}

# Check if an event has already been opened
is_opened() {
  local event_id="$1"
  grep -qF "|${event_id}" "$OPENED_LOG" 2>/dev/null
}

# Mark an event as opened
mark_opened() {
  local event_id="$1"
  echo "$(date +%s)|${event_id}" >> "$OPENED_LOG"
}

# Extract meeting URL from text
extract_meeting_url() {
  local text="$1"
  echo "$text" | grep -oE 'https?://(([a-z0-9]+\.)?zoom\.us|meet\.google\.com|teams\.microsoft\.com|([a-z0-9]+\.)?webex\.com)/[^ ]*' | head -1
}

cleanup_old_entries

now_epoch=$(date +%s)

# Get today's events (excluding all-day events) with event marker prefix
raw=$(icalBuddy -ea -nc -b "${EVENT_MARKER} " -nrd -df '' -tf '%H:%M' \
  -iep 'title,datetime,url,location,notes' \
  -po 'title,datetime,url,location,notes' \
  -ps '/ :: /' eventsToday 2>/dev/null || true)

if [[ -z "$raw" ]]; then
  exit 0
fi

# Merge continuation lines (lines not starting with marker) into single-line events
events=$(echo "$raw" | awk -v marker="$EVENT_MARKER" '
  $0 ~ "^" marker {
    if (buf != "") print buf
    buf = $0
    next
  }
  { buf = buf " " $0 }
  END { if (buf != "") print buf }
')

while IFS= read -r line; do
  [[ -z "$line" ]] && continue

  # Strip event marker prefix
  line="${line#${EVENT_MARKER} }"

  # Parse title and start time
  # Format: "title :: HH:MM - HH:MM :: ..."
  title=$(echo "$line" | sed 's/ :: .*//' | xargs)
  [[ -z "$title" ]] && continue
  start_time=$(echo "$line" | grep -oE '[0-9]{1,2}:[0-9]{2} - ' | head -1 | sed 's/ - //') || true
  [[ -z "$start_time" ]] && continue

  # Convert start time to epoch for comparison
  start_epoch=$(date -j -f '%H:%M' "$start_time" +%s 2>/dev/null) || continue
  diff=$(( start_epoch - now_epoch ))

  # Only process events starting within -60s to +120s from now
  if (( diff < -60 || diff > 120 )); then
    continue
  fi

  # Create a unique ID from the title, date, and start time
  event_id="${title}_$(date +%Y%m%d)_${start_time}"

  if is_opened "$event_id"; then
    continue
  fi

  # Try to extract meeting URL from the entire event line
  url=$(extract_meeting_url "$line")

  if [[ -z "$url" ]]; then
    continue
  fi

  # Notify and open
  terminal-notifier \
    -title "Meeting Starting" \
    -message "$title" \
    -sound default \
    2>/dev/null || true

  open "$url"
  mark_opened "$event_id"

  echo "$(date '+%Y-%m-%d %H:%M:%S') Opened: $title -> $url"
done <<< "$events"
