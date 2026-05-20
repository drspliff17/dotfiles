#!/usr/bin/env bash

# INIT / SETUP

[[ $EUID -ne 0 ]] && {
  exec sudo "$0" "$@"
}

SDDM_STATE_DATA="/home/drspliff/.config/bash/state/sddm_state.yml"

THEME_DIR="/usr/share/sddm/themes"
CONFIG_FILE="/etc/sddm.conf.d/sddm.conf"
CURRENT_THEME=$(yq '.currentTheme' "$SDDM_STATE_DATA")

MODE=""
SELECTED_THEME=""

# HELPERS

_validTheme() {
  [[ ! -d "$THEME_DIR/$SELECTED_THEME" ]] && return 1
  return 0
}

_update() {
  cat >"$CONFIG_FILE" <<EOF
  [Theme]
  Current=$SELECTED_THEME
EOF
  echo "Updated $CONFIG_FILE: Theme = $SELECTED_THEME"
  yq -i ".currentTheme = \"$SELECTED_THEME\"" "$SDDM_STATE_DATA"
}

_printHelp() {
  cat <<EOF
sddm_set_theme
--------------
State file: $SDDM_STATE_DATA

Origin script: ~/.config/bash/scripts/sddm_set_theme.sh
Symlnk script: /usr/local/bin/sddm_set_theme (* sudo NOPASSWD)
NOPASSWD file: /etc/sudoers.d/sddm_theme
THEME_DIR loc: $THEME_DIR

Modes:
-h | help   - View this message
-r | random - Automatically pick theme from THEME_DIR
-s | set    - Specify theme (dir name relative to THEME_DIR)
-t | toggle - Toggle StateFile.randomThemeOnBoot value
EOF
}

# Main - Parsing

while [[ "$#" -gt 0 ]]; do
  case "$1" in
  -h | help)
    _printHelp
    exit 0
    ;;
  -r | random)
    shift
    MODE="random"
    break
    ;;
  -s | set)
    shift
    MODE="set"
    SELECTED_THEME="$1"
    shift
    if [[ -z "$SELECTED_THEME" ]]; then
      echo "[ERROR] Requires Theme to be given" >&2
      exit 1
    fi
    ;;
  -t | toggle)
    shift
    if [[ "$(yq '.randomThemeOnBoot' "$SDDM_STATE_DATA")" == 0 ]]; then
      yq -i '.randomThemeOnBoot = 1' "$SDDM_STATE_DATA" && echo "StateFile.randomThemeOnBoot: Set to TRUE"
      exit 0
    else
      yq -i '.randomThemeOnBoot = 0' "$SDDM_STATE_DATA" && echo "StateFile.randomThemeOnBoot: Set to FALSE"
      exit 0
    fi
    ;;
  -*)
    echo "[ERROR] Unknown Option: $1" >&2
    exit 1
    ;;
  *)
    echo "[ERROR] Unexpected Value: $1" >&2
    exit 1
    ;;
  esac
done

# Main - Execution

[[ -z "$MODE" ]] && MODE="random"
case "$MODE" in
set)
  ! _validTheme && echo "[ERROR] Invalid Theme: $SELECTED_THEME" >&2 && exit 1
  _update && exit 0
  ;;
random)
  [[ "$(yq '.randomThemeOnBoot' "$SDDM_STATE_DATA")" == 0 ]] && {
    echo "Aborting, Reason: StateFile.randomThemeOnBoot is currently FALSE" >&2
    exit 1
  }

  mapfile -t THEMES < <(
    find "$THEME_DIR" -mindepth 1 -maxdepth 1 -type d -printf "%f\n"
  )

  FILTERED=()
  for theme in "${THEMES[@]}"; do
    if [[ "$theme" != "$CURRENT_THEME" ]]; then
      FILTERED+=("$theme")
    fi
  done

  if [ ${#FILTERED[@]} -eq 0 ]; then
    FILTERED=("${THEMES[@]}")
  fi

  SELECTED_THEME="${FILTERED[RANDOM % ${#FILTERED[@]}]}"
  _update && exit 0
  ;;
esac
