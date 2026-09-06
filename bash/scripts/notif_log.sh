#!/usr/bin/env bash

LOCKFILE="/tmp/notif_log.lock"

if [[ -e "$LOCKFILE" ]]; then
  PID="$(cat "$LOCKFILE")"
  if kill -0 "$PID" 2>/dev/null; then
    echo "Script already running (PID: $PID), stopping old instance..."
    kill "$PID"
    sleep 1
  fi
fi

echo $$ >"$LOCKFILE"
trap 'rm -f "$LOCKFILE"' EXIT

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
    skip=0

    while read -r line; do

      if $DEBUG; then
        echo "[DEBUG] $line"
      fi

      if [[ "$line" =~ string\ \"(.*)\" ]]; then

        value="${BASH_REMATCH[1]}"

        value="${value//\\n/$'\n'}"
        value="${value//\\t/$'\t'}"

        case $state in

        0)
          app_name="$value"

          case "$app_name" in
          nh | no-history | view-notification-details | nh-center-text | ts | theme_selector)
            skip=1
            break
            ;;
          esac

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

        3)
          body="$value"
          state=4
          ;;

        esac
      fi

      # Don't break based on "]".
      # The body/strings may contain arbitrary characters.

      # Once we've captured the body, we're done.
      if [[ "$state" -eq 4 ]]; then
        break
      fi

    done

    [[ "$skip" -eq 1 ]] && continue

    ts="$(date -Iseconds)"

    append "$ts" "$app_name" "$icon" "$title" "$body" ""

  fi

done
