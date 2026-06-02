#!/usr/bin/env bash

LIB_NOTIFY="$HOME/.config/bash/lib/notify.sh"
source "$LIB_NOTIFY" || {
  notify-send -a center-text -t 1500 -u normal "Error" "Could not source required lib: $LIB_NOTIFY"
  exit 1
}

LIB_WOFI="$HOME/.config/bash/lib/wofi_construct.sh"
source "$LIB_WOFI" || {
  _notify -a ct -e -u normal "Could not source required lib: $LIB_WOFI"
  exit 1
}

MODE=""
LOOP=true

VIDSRC_BASE="https://vidsrc-embed.ru/embed"

TMDB_T="$(tr -d '\r\n ' <"$HOME/dev/data/env/.tmdb.env")"
TMDB_QUERY=""
TMDB_TYPE=""
TMDB_RESULT=""
TMDB_RESULT_COUNT=0

TMDB_CACHE_QUERY=""
TMDB_LOG_OUTPUT="$HOME/dev/data/misc/watchstuff_output.log"

TMDB_ID_SELECTED=""
TMDB_SEASON_SELECTED=""
TMDB_EPISODE_SELECTED=""

TMDB_EMBED_URL=""

# Handle tmp file cleanup
_cleanup() {
  # _logOutput
  [[ -e "$TMDB_CACHE_QUERY" ]] && rm "$TMDB_CACHE_QUERY"
}

trap '_cleanup' EXIT

while [[ "$#" -gt 0 ]]; do
  case "$1" in

  -q | --query)
    MODE="QUERY"
    TMDB_QUERY="$2"
    shift 2
    ;;

  -s | --season)
    [[ ! "$2" =~ ^[0-9]+$ || -z "$2" ]] && _notify -a ct -e "Invalid Season. Must be a number, got: $2" && exit 1
    TMDB_SEASON_SELECTED="$2"
    shift 2
    ;;

  -e | --episode)
    [[ ! "$2" =~ ^[0-9]+$ || -z "$2" ]] && _notify -a ct -e "Invalid Episode. Must be a number, got: $2" && exit 1
    TMDB_EPISODE_SELECTED="$2"
    shift 2
    ;;

  -i | --id)
    #TODO: Add validator for explicit id
    MODE="LAUNCH"
    TMDB_ID_SELECTED="$2"
    shift 2
    ;;

  -t | --type)
    [[ -z "$2" ]] && _notify -a ct -e "Type Expected" && exit 1
    case "$2" in
    tv | movie)
      TMDB_TYPE="$2"
      shift 2
      ;;
    *)
      _notify -a ct -e "Invalid Type. Got: $2, expected: [tv movie]" && exit 1
      ;;
    esac
    ;;

  -*)
    _notify -a ct "[IGNORING] Unknown option provided: $1" && shift
    ;;

  *)
    _notify -a ct "[IGNORING] Unknown value provided: $1" && shift
    ;;

  esac
done
[[ -z "$MODE" ]] && _notify -a ct -e "Expected MODE to be set. Exiting" && exit 1

# Store $TMDB_RESULT to $TMDB_CACHE_QUERY for use during script lifecycle
_cacheQuery() {
  TMDB_CACHE_QUERY="$(mktemp)"
  echo "$TMDB_RESULT" | jq >"$TMDB_CACHE_QUERY" && return 0
}

_logOutput() {
  mkdir -p "$(dirname "$TMDB_LOG_OUTPUT")"
  echo -e "$(date)\n" >"$TMDB_LOG_OUTPUT" && cat "$TMDB_RESULT" | jq >>"$TMDB_LOG_OUTPUT"
}

# Updates $TMDB_RESULT, using $TMDB_QUERY
_curlQuery() {
  local count
  TMDB_RESULT="$(curl -s \
    "https://api.themoviedb.org/3/search/multi?query=$(printf '%s' "$TMDB_QUERY" | jq -sRr @uri)" \
    -H "Authorization: Bearer $TMDB_T" \
    -H "Accept: application/json")"

  TMDB_RESULT_COUNT="$(echo "$TMDB_RESULT" | jq -r '.results | length')"
  [[ "$TMDB_RESULT_COUNT" -eq 0 ]] && return 1
  return 0
}

# Updates $TMDB_RESULT, using $TMDB_ID_SELECTED and $TMDB_TYPE
_curlID() {
  [[ -z "$TMDB_ID_SELECTED" ]] && _notify -a ct -e "Requires ID to query" && exit 1
  [[ -z "$TMDB_TYPE" ]] && _notify -a ct -e "Requires Type to query" && exit 1

  TMDB_RESULT="$(curl -s \
    "https://api.themoviedb.org/3/${TMDB_TYPE}/${TMDB_ID_SELECTED}" \
    -H "Authorization: Bearer $TMDB_T" \
    -H "AcceptL application/json")"

  echo "$TMDB_RESULT" | jq -e '.id' >/dev/null 2>&1 || return 1
  return 0
}

# Echo
_constructEmbedURL() {
  local type
  if [[ -z "$TMDB_CACHE_QUERY" ]]; then
    if ! _curlID; then
      _notify -a ct -e "Failed to curl. ID = $TMDB_ID_SELECTED | TYPE = $TMDB_TYPE" && exit 1
    else
      type="$TMDB_TYPE"
    fi
  else
    type="$(cat "$TMDB_CACHE_QUERY" | jq -r --argjson id "$TMDB_ID_SELECTED" '.results[] | select(.id == $id) | .media_type')"
  fi
  case "$type" in
  tv)
    #TODO: Add some validation of season / episode number
    echo "$VIDSRC_BASE/$type/$TMDB_ID_SELECTED/$TMDB_SEASON_SELECTED-$TMDB_EPISODE_SELECTED"
    ;;
  movie)
    echo "$VIDSRC_BASE/$type/$TMDB_ID_SELECTED"
    ;;
  esac
}

while $LOOP; do
  case "$MODE" in
  QUERY)
    if ! _curlQuery; then
      _notify -a ct "No results found for: $TMDB_QUERY ($TMDB_TYPE)"
    else
      _cacheQuery
      TMDB_ID_SELECTED="$(
        echo "$TMDB_RESULT" |
          jq -r --arg type "$TMDB_TYPE" '
      .results[]
      | select(.media_type != "person")
      | select($type == "" or .media_type == $type)
      | "\(.name // .title) [\(.media_type)] (\(.id))"
    ' |
          wofi -d |
          sed -E 's/.*\(([^)]+)\)$/\1/'
      )"
      [[ -z "$TMDB_ID_SELECTED" ]] && exit 0
      MODE="LAUNCH"
    fi
    ;;
  LAUNCH)
    TMDB_EMBED_URL="$(_constructEmbedURL)"
    firefox --new-window "$TMDB_EMBED_URL"
    LOOP=false
    ;;
  esac
done
