#!/usr/bin/env bash

LOGFILE="${1:-$HOME/dev/data/notifications.json}"
DEBUG=false

mkdir -p "$(dirname "$LOGFILE")"

if [ ! -s "$LOGFILE" ]; then
  echo "[]" >"$LOGFILE"
fi

append() {
  jq \
    --arg ts "$1" \
    --arg app "$2" \
    --arg icon "$3" \
    --arg title "$4" \
    --arg body "$5" \
    --arg hint_icon "$6" \
    '.
    + [{
        timestamp: $ts,
        app_name: $app,
        icon: (if $hint_icon != "" then $hint_icon else $icon end),
        app_icon: $icon,
        hint_icon: $hint_icon,
        title: $title,
        body: $body
      }]' "$LOGFILE" >"$LOGFILE.tmp" && mv "$LOGFILE.tmp" "$LOGFILE"
}

dbus-monitor "interface='org.freedesktop.Notifications'" | while read -r line; do

  if [[ "$line" == *"member=Notify"* ]]; then

    app_name=""
    icon=""
    title=""
    body=""
    state=0

    while read -r line; do
      if $DEBUG; then
        echo "[DEBUG] $line | $value"
      fi

      if [[ "$line" =~ string\ \"(.*)\" ]]; then
        value="${BASH_REMATCH[1]}"

        value="${value//\\n/
}"
        value="${value//\\t/    }"

        case $state in
        0)
          app_name="$value"
          state=1
          ;;
        1)
          icon="$value"
          state=2
          ;;
        2)
          title="$value"
          state=3
          ;;
        3) body+="$value " ;;
        esac
      fi

      if [[ "$line" == *"]"* ]]; then
        break
      fi

    done

    ts=$(date -Iseconds)

    append "$ts" "$app_name" "$icon" "$title" "$body"

  fi

done
