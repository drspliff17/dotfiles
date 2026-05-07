#!/usr/bin/env bash

scr_fixFilename="$HOME/.config/bash/scripts/fixYoutubeMusic_Files.sh"
scr_fixMp3="$HOME/.config/bash/scripts/fmp3.sh"

[[ ! -f "$scr_fixFilename" || ! -f "$scr_fixMp3" ]] && {
  echo -e "[ERROR] Missing script dependancy. Expected:\n$scr_fixFilename\n$scr_fixMp3" >&2
  exit 1
}

givenURL="$1"
assumeArtist="$2"
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

ytdlp_artistName=""
[[ -z "$assumeArtist" ]] && read -rp "[INIT] Please enter Artist Name:  " ytdlp_artistName || ytdlp_artistName="$(echo "$(basename $PWD)" | sed 's/_/ /g')"
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
