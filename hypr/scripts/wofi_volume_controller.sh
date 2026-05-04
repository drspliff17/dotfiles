#!/usr/bin/env bash

#TODO: (Low Priority) -> Eliminate redundant sink-count calculation, by caching value early in script
#      (Low Priority) -> Refine comments and, possibly refactor areas, clean it up a touch, basically

# Arguments passed to wofi
w_prompt=""
w_width="25%"
w_height="35%"
w_sort="default"
w_config=""
w_columns=""
w_lines=""

w_args=()
w_volumeOptions="0%\n5%\n10%\n15%\n20%\n25%\n30%\n35%\n40%\n45%\n50%\n55%\n60%\n65%\n70%\n75%\n80%\n85%\n90%\n95%\n100%"

# Set by wofi
w_selectedVolume=""
sink_input_id=""

mode=""
volumeSelected=1

# Construct Wofi arguments
_constructArgs() {
  w_args=()
  w_args+=("--prompt" "$w_prompt")
  w_args+=("--width" "$w_width")
  w_args+=("--height" "$w_height")
  [[ -n "$w_sort" ]] && w_args+=("-O" "$w_sort")
  [[ -n "$w_config" ]] && w_args+=("--conf" "$w_config")
  [[ -n $w_columns ]] && w_args+=("--columns" "$w_columns")
  [[ -n $w_lines ]] && w_args+=("--lines" "$w_lines")
}

# Establish current mode
case "$1" in
all | a)
  mode="all_player"
  ;;
system | s)
  mode="system_sounds"
  ;;
player | p)
  mode="pick_player"
  ;;
esac
[[ -z "$mode" ]] && mode="unset"

# Wrapper for notify-send
_notify() {
  local msg="$1"
  notify-send -a center-text -u low -t 1800 "$msg"
}

# Get audio sinks for Wofi
_getStreams() {
  pactl list sink-inputs | awk '
    /Sink Input #/ {
      if (id) {
        printf "%s - %s (%s)\n", id, name, vol
      }
      id=$3; sub("#","",id)
      name="unknown"
      vol="?"
    }

    /application.name =/ {
      gsub(/"/,"")
      name = substr($0, index($0,"=")+2)
    }

    /Volume: front-left:/ {
      for (i=1;i<=NF;i++) {
        if ($i ~ /%/) {
          vol=$i
          gsub(/[^0-9%]/,"",vol)
        }
      }
    }

    END {
      if (id) {
        printf "%s - %s (%s)\n", id, name, vol
      }
    }
  '
}

# Return sink volume for specified sink ID
_getSinkVolume() {
  pactl list sink-inputs |
    awk -v id="$sink_input_id" '
    $0 ~ "Sink Input #"id {found=1}
    found && /Volume: front-left:/ {
      for (i=1;i<=NF;i++) {
        if ($i ~ /%/) {
          gsub(/[^0-9%]/,"",$i)
          print $i
          exit
        }
      }
    }
  '
}

_validateVolume() {
  local input="$1"
  if [[ "$input" =~ ^[0-9]+%?$ ]]; then
    val=${input%\%}
    if ((val < 0 || val > 100)); then
      return 1
    fi
    echo "${val}%"
    return 0
  fi

  return 1
}

_validateSinkInput() {
  local id="$1"
  pactl list sink-inputs | grep -q "Sink Input #$id"
}

# Main
case "$mode" in
# 'Menu' to set mode and re-exec
"unset")
  w_prompt="Select Volume Control Mode" && _constructArgs
  sub="$(echo -e "System\nPlayer\nAll Sinks" | wofi -d "${w_args[@]}")"
  [[ -z "$sub" ]] && exit 1
  case "$sub" in
  "System")
    mode="system_sounds"
    sub="s"
    ;;
  "Player")
    mode="pick_player"
    sub="p"
    ;;
  "All Sinks")
    mode="all_player"
    sub="a"
    ;;
  *)
    exit 1
    ;;
  esac
  exec "$0" "$sub"
  ;;

# Choose Audio Sink (Skipped if count == 1)
"pick_player")
  w_prompt="Select Audio Sink" && _constructArgs
  while [[ "$volumeSelected" -eq 1 ]]; do
    streams=$(_getStreams)
    [[ -z "$streams" ]] && _notify "No Audio Sinks Detected" && exit 1

    stream_count=$(printf "%s\n" "$streams" | sed '/^\s*$/d' | wc -l)
    if [[ "$stream_count" -eq 1 ]]; then
      selection="$streams"
    else
      selection="$(printf '%s\n' "$streams" | wofi -d "${w_args[@]}")"
      [[ -z "$selection" ]] && exit 1
    fi
    sink_input_id="${selection%% *}"
    sink_display_name="${selection#*-}"
    sink_clean_name="${sink_display_name%% (*}"
    sink_current_volume="$(_getSinkVolume)"
    if ! _validateSinkInput "$sink_input_id"; then
      _notify "Invalid Audio Sink ID" && exit 1
    fi

    w_prompt="Select Volume ($sink_clean_name ): Currently $sink_current_volume" && _constructArgs
    w_selectedVolume="$(echo -e "$w_volumeOptions" | wofi -d "${w_args[@]}")"
    [[ -z "$w_selectedVolume" ]] && exit 1
    w_selectedVolume="$(_validateVolume "$w_selectedVolume")" || {
      _notify "Invalid Audio Value: 0(%) - 100(%) "
      exit 1
    }
    volumeSelected=0
  done
  pactl set-sink-input-volume "$sink_input_id" "$w_selectedVolume" && _notify "Volume set $sink_display_name ==> $w_selectedVolume" && exit 0
  ;;

# Set Volume for all Audio Sinks
"all_player")
  sinks_count=$(pactl list sink-inputs | grep -c "Sink Input #")
  [[ "$sinks_count" -eq 0 ]] && _notify "No Audio Sinks Detected" && exit 1

  w_prompt="Select Volume For All (Or Enter Value 0-100)" && _constructArgs
  w_selectedVolume="$(echo -e "$w_volumeOptions" | wofi -d "${w_args[@]}")"
  [[ -z "$w_selectedVolume" ]] && exit 1
  w_selectedVolume="$(_validateVolume "$w_selectedVolume")" || {
    _notify "Invalid Audio Value: 0(%) - 100(%) "
    exit 1
  }

  pactl list sink-inputs | awk '
    /Sink Input #/ {
      id=$3
      sub("#", "", id)
      print id
    }
  ' | while read -r id; do
    pactl set-sink-input-volume "$id" "$w_selectedVolume"
  done

  exit 0
  ;;

# Set volume for System Sound Sink
"system_sounds")
  w_prompt="System Volume (Default Output)" && _constructArgs

  current_volume=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print $2 * 100 "%"}')

  w_selectedVolume="$(echo -e "$w_volumeOptions" | wofi -d "${w_args[@]}")"
  [[ -z "$w_selectedVolume" ]] && exit 1
  w_selectedVolume="$(_validateVolume "$w_selectedVolume")" || {
    _notify "Invalid Audio Value: 0(%) - 100(%) "
    exit 1
  }

  wpctl set-volume @DEFAULT_AUDIO_SINK@ "$w_selectedVolume"
  _notify "System volume set: $w_selectedVolume (was $current_volume)"
  exit 0
  ;;
esac
