#!/bin/sh
if /usr/bin/pmset -g ps | /usr/bin/grep -q "'AC Power'"; then
  want=1
else
  want=0
fi
have=$(/usr/bin/pmset -g | /usr/bin/awk '/SleepDisabled/ { print $2 }')
if [ "${have:-0}" != "$want" ]; then
  /usr/bin/pmset -a disablesleep "$want"
  echo "$(/bin/date '+%H:%M:%S') disablesleep ${have:-0} -> $want"
  # powerd evaluates clamshell sleep only when the lid, display or power
  # source changes, so a lid already closed at unplug would keep the Mac awake.
  if [ "$want" = 0 ] && /usr/sbin/ioreg -r -k AppleClamshellState -d 1 | /usr/bin/grep -q '"AppleClamshellState" = Yes'; then
    echo "$(/bin/date '+%H:%M:%S') lid closed on battery, sleeping now"
    /usr/bin/pmset sleepnow
  fi
fi
