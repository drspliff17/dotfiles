#!/usr/bin/env bash

#TODO: Implement a per season/episode stat (?)

#TODO: Refactor to allow passing from query to stat, with prompt before launch

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

# Main Ctl vars
MODE=""
LOOP=true

#
# Const vars

VIDSRC_BASE="https://vidsrc-embed.ru/embed"
TMDB_T="$(tr -d '\r\n ' <"$HOME/dev/data/env/.tmdb.env")"

#
# Mode vars

TMDB_QUERY=""

#
# Curl Response vars

TMDB_RESULT=""
TMDB_RESULT_COUNT=0

TMDB_DO_STAT=false
TMDB_PASS_STAT=false

#
# Stores tmp path for curl query response
TMDB_CACHE_QUERY=""

#
# URL Construct vars

TMDB_TYPE=""
TMDB_ID_SELECTED=""
TMDB_SEASON_SELECTED=""
TMDB_EPISODE_SELECTED=""

#
# Constructed URLS

TMDB_EMBED_URL=""
TMDB_POSTER_URL=""

#
# Stores wofi vars
W_ARGS=()

#
# Handle tmp file cleanup
_cleanup() {
  [[ -e "$TMDB_CACHE_QUERY" ]] && rm "$TMDB_CACHE_QUERY"
}

trap '_cleanup' EXIT

#
# Arg Parsing
while [[ "$#" -gt 0 ]]; do
  case "$1" in

  -st | --stat)
    TMDB_DO_STAT=true
    shift
    ;;

  -ps | --pass)
    TMDB_PASS_STAT=true
    shift
    ;;

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

# Update $TMDB_POSTER_URL, using TMDB_RESULT.poster_path
_constructPosterURL() {
  local p="$(echo "$TMDB_RESULT" | jq -r '.poster_path // .backdrop_path')"
  local s="w185"
  TMDB_POSTER_URL="https://image.tmdb.org/t/p/${s}/${p}"
}

# Update $TMDB_EMBED_URL, using URL Construct vars
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

    #NOTE: TEMP ASSERTION
    [[ -z "$TMDB_EPISODE_SELECTED" ]] && TMDB_EPISODE_SELECTED=1
    [[ -z "$TMDB_SEASON_SELECTED" ]] && TMDB_SEASON_SELECTED=1

    TMDB_EMBED_URL="$VIDSRC_BASE/$type/$TMDB_ID_SELECTED/$TMDB_SEASON_SELECTED-$TMDB_EPISODE_SELECTED"
    ;;
  movie)
    TMDB_EMBED_URL="$VIDSRC_BASE/$type/$TMDB_ID_SELECTED"
    ;;
  esac
}

#
# Store $TMDB_RESULT to $TMDB_CACHE_QUERY for use during script lifecycle
_cacheQuery() {
  TMDB_CACHE_QUERY="$(mktemp)"
  echo "$TMDB_RESULT" | jq >"$TMDB_CACHE_QUERY" && return 0
}

#
# Updates $TMDB_RESULT && $TMDB_RESULT_COUNT, using $TMDB_QUERY. Returns false if no results are found
_curlQuery() {
  TMDB_RESULT="$(curl -s \
    "https://api.themoviedb.org/3/search/multi?query=$(printf '%s' "$TMDB_QUERY" | jq -sRr @uri)" \
    -H "Authorization: Bearer $TMDB_T" \
    -H "Accept: application/json")"

  TMDB_RESULT_COUNT="$(echo "$TMDB_RESULT" | jq -r '.results | length')"
  [[ "$TMDB_RESULT_COUNT" -eq 0 ]] && return 1
  return 0
}

# Updates $TMDB_RESULT, using $TMDB_ID_SELECTED and $TMDB_TYPE. Returns false if id is not found
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

_statID() {
  if ! _curlID; then
    _notify -a ct -e "Could not find result for $TMDB_ID_SELECTED" && return 1
  fi

  local statString

  _nextAir() {
    local nextData="$(echo "$TMDB_RESULT" | jq '.next_episode_to_air')"
    [[ -z "$nextData" || "$nextData" = "null" ]] && echo "" && return 0
    echo "Next Episode: $(echo "$nextData" | jq -r '"\(.air_date) [\(.name)]"')"
  }

  case "$TMDB_TYPE" in
  tv)
    statString="$(
      cat <<EOF
[TV Show]
Name: $(echo "$TMDB_RESULT" | jq -r '.name')
Season Count: $(echo "$TMDB_RESULT" | jq -r '.number_of_seasons // "unknown"')
Episode Count: $(echo "$TMDB_RESULT" | jq -r '.number_of_episodes // "unknown"')
First Aired: $(echo "$TMDB_RESULT" | jq -r '.first_air_date // "unknown"')
Last Aired: $(echo "$TMDB_RESULT" | jq -r '.last_air_date // "unknown"')
Status: $(echo "$TMDB_RESULT" | jq -r '.status // "unknown"')
$(_nextAir)
EOF
    )"
    [[ -t 1 ]] && {
      _constructPosterURL
      kitty +kitten icat --align left "$TMDB_POSTER_URL"
    }
    _notify -a ct "$statString"
    ;;

  movie)

    ;;
  esac

  # $TMDB_PASS_STAT && MODE="LAUNCH"
  return 0
}

[[ "$MODE" != "QUERY" && $TMDB_DO_STAT ]] && MODE="STAT"
while $LOOP; do

  case "$MODE" in

  QUERY)
    if ! _curlQuery; then
      _notify -a ct "No results found for: $TMDB_QUERY ($TMDB_TYPE)" && exit 1
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
          wofi -d "${W_ARGS[@]}" |
          sed -E 's/.*\(([^)]+)\)$/\1/'
      )"
      [[ -z "$TMDB_ID_SELECTED" ]] && exit 0
      if $TMDB_DO_STAT; then
        MODE="STAT"
      else
        MODE="LAUNCH"
      fi
    fi
    ;;

  STAT)
    if ! _statID; then
      exit 1
    fi
    LOOP=false
    ;;

  LAUNCH)
    _constructEmbedURL
    firefox --new-window "$TMDB_EMBED_URL" &
    LOOP=false
    ;;

  esac
done
