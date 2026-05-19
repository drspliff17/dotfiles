#!/usr/bin/env bash

THEME_DIR="/usr/share/sddm/themes"
CONFIG_FILE="/etc/sddm.conf.d/sddm.conf"

CURRENT_THEME=$(grep -Po '^Current=\K.*' "$CONFIG_FILE" 2>/dev/null)

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

RANDOM_THEME="${FILTERED[RANDOM % ${#FILTERED[@]}]}"
cat >"$CONFIG_FILE" <<EOF
[Theme]
Current=$RANDOM_THEME
EOF
