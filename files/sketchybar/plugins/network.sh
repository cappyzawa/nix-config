#!/bin/bash

INTERFACE="en0"

# Get current bytes
read RX_BYTES TX_BYTES <<< $(netstat -ib -I "$INTERFACE" | tail -1 | awk '{print $7, $10}')

# Cache file for previous values
CACHE_FILE="/tmp/sketchybar_network_$INTERFACE"

if [ -f "$CACHE_FILE" ]; then
  read PREV_RX PREV_TX PREV_TIME < "$CACHE_FILE"
  CURRENT_TIME=$(date +%s)

  TIME_DIFF=$((CURRENT_TIME - PREV_TIME))
  if [ "$TIME_DIFF" -gt 0 ]; then
    RX_RATE=$(( (RX_BYTES - PREV_RX) / TIME_DIFF / 1024 ))
    TX_RATE=$(( (TX_BYTES - PREV_TX) / TIME_DIFF / 1024 ))

    # Format output
    if [ "$RX_RATE" -gt 1024 ]; then
      RX_LABEL="$(( RX_RATE / 1024 ))MB/s"
    else
      RX_LABEL="${RX_RATE}KB/s"
    fi

    if [ "$TX_RATE" -gt 1024 ]; then
      TX_LABEL="$(( TX_RATE / 1024 ))MB/s"
    else
      TX_LABEL="${TX_RATE}KB/s"
    fi

    sketchybar --set "$NAME" label="↓${RX_LABEL} ↑${TX_LABEL}"
  fi
fi

echo "$RX_BYTES $TX_BYTES $(date +%s)" > "$CACHE_FILE"
