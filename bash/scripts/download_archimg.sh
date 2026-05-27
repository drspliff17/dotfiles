DIR="$HOME/Pictures/archimg"
DO_DOWNLOAD=1

# Prompt to clear and redownload, if output directory is found
[[ -d "$DIR" ]] && {
  DO_DOWNLOAD=0
  read -rp "Found $DIR already, would you like to remove contents, and redownload? (no will skip to conversion) [Y/n]:  " confirm
  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    DO_DOWNLOAD=1
    rm -r "$DIR"
  else
    echo "Skipping download process"
  fi
}

mkdir -p "$DIR"
cd "$DIR"

# Grab images
[[ "$DO_DOWNLOAD" -eq 1 ]] && {
  echo "Starting download..."
  time seq -w 001 297 | xargs -P 16 -I{} bash -c '
  url="https://archimg.cc/assets/{}.jpg"
  out="{}.jpg"

  if curl -sf "$url" -o "$out"; then
      echo "downloaded $out"
  fi
  '
}

# Require ffmpeg for conversion
which ffmpeg 2>&1 >/dev/null || {
  echo "Cannot find ffmpeg, do you have it installed?" >&2
  exit 1
}

# File conversion
read -rp "Would you like to convert these files to .png, this will take a moment. (Recommended) [Y/n]:  " confirm
[[ ! "$confirm" =~ ^[Yy]$ ]] && echo "[ABORTED]" && exit 0
for f in "$DIR"/*.jpg; do
  ffmpeg -i "$f" "${f%.jpg}.png"
done
