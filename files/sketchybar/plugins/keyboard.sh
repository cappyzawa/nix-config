#!/bin/bash

SOURCE=$(defaults read ~/Library/Preferences/com.apple.HIToolbox.plist AppleCurrentKeyboardLayoutInputSourceID 2>/dev/null)

case "$SOURCE" in
  *"ABC"*)
    LABEL="EN"
    ;;
  *"Japanese"*|*"Kotoeri"*)
    LABEL="JP"
    ;;
  *"Hiragana"*)
    LABEL="あ"
    ;;
  *)
    LABEL=$(echo "$SOURCE" | sed 's/.*\.//' | cut -c1-2 | tr '[:lower:]' '[:upper:]')
    ;;
esac

sketchybar --set "$NAME" label="$LABEL"
