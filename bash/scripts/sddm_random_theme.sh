#!/usr/bin/env bash

SDDM_THEME_DIR="/usr/share/sddm/themes"
C_FILE="/etc/sddm.conf.d/sddm.conf"
THEMES=($(ls -i "$SDDM_THEME_DIR"))
R_THEME=$(find "$SDDM_THEME_DIR" -mindepth 1 -maxdepth 1 -type d -printf "%f\n" | shuf -n 1)
cat <<EOF >"$C_FILE"
[Theme]
Current=$R_THEME
EOF
