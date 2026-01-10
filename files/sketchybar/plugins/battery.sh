#!/bin/bash

PERCENTAGE=$(pmset -g batt | grep -Eo "\d+%" | cut -d% -f1)
CHARGING=$(pmset -g batt | grep 'AC Power')

if [ -n "$CHARGING" ]; then
  ICON="􀢋"
  COLOR=0xff9ece6a
elif [ "$PERCENTAGE" -gt 80 ]; then
  ICON="􀛨"
  COLOR=0xff9ece6a
elif [ "$PERCENTAGE" -gt 60 ]; then
  ICON="􀺸"
  COLOR=0xff9ece6a
elif [ "$PERCENTAGE" -gt 40 ]; then
  ICON="􀺶"
  COLOR=0xffe0af68
elif [ "$PERCENTAGE" -gt 20 ]; then
  ICON="􀛩"
  COLOR=0xffff9e64
else
  ICON="􀛪"
  COLOR=0xfff7768e
fi

sketchybar --set "$NAME" icon="$ICON" icon.color="$COLOR" label="${PERCENTAGE}%"
