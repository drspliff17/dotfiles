#!/usr/bin/env bash

givenURL="$1"

if [[ -z "$givenURL" ]]; then
  read -rp "[INIT] Please enter URL:  " ytdlp_url
else
  ytdlp_url="$givenURL"
fi
[[ -z "$ytdlp_url" ]] && echo "[ERROR] URL must be provided" >&2 && exit 1
curl -fsSL --max-time 5 "$ytdlp_url" >/dev/null || {
  echo "[ERROR] Bad URL" >&2 && exit 1
}

read -rp "[INIT] Please enter target directory (or leave blank for CWD):  " ytdlp_targdir
[[ -z "$ytdlp_targdir" ]] && ytdlp_targdir="$PWD"
[[ ! -d "$ytdlp_targdir" ]] && echo "[ERROR] Directory does not exist" >&2 && exit 1

read -rp "[INIT] Please enter Artist Name:  " ytdlp_artistName
[[ -z "$ytdlp_artistName" ]] && echo "[ERROR] Artist Name must be provided" >&2 && exit 1

read -rp "[INIT] Please enter Album Name:  " ytdlp_albumName
[[ -z "$ytdlp_albumName" ]] && echo "[ERROR] Album Name must be provided" >&2 && exit 1

tmpdir="$(mktemp -d)" || {
  echo "[ERROR] Failed to create temp directory" >&2 && exit 1
}
trap 'rm -rf "$tmpdir"' EXIT

prevDir="$PWD"
cd "$tmpdir"
yt-dlp -x --audio-format mp3 "$ytdlp_url"
$HOME/.config/bash/scripts/fixYoutubeMusic_Files.sh
$HOME/.config/bash/scripts/fmp3.sh -a "$ytdlp_artistName" -sa "$ytdlp_albumName" -t
mv "$tmpdir"/* "$ytdlp_targdir"
echo "[FINISHED]"
