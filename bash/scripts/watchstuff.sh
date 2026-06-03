#!/usr/bin/env bash

#TODO: Implement a per season/episode stat (?)

#TODO: Refactor to allow passing from query to stat, with prompt before launch

#TODO: build interactive menu prompts for when required args are not provided (or as a mode?)

#TODO: Cache last query, make mode to jump back to last stat'd ID
# Cache curled images when selecting an id for the first time

#TODO: Create a state file that can track things such as the $VIDSRC_BASE

#TODO: Add Vidsrc 404 filter to results

#TODO: Create log system, which could then be parsed for history (or just make a history thing by itself)

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
NEXT_MODE=""
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
TMDB_RESULT_IDS=()

TMDB_DO_STAT=false
TMDB_TV_STAT_INCLUDE_SEASONS=true

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
TMDB_IMAGE_URL=""

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
    NEXT_MODE="STAT"
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

# Update $TMDB_IMAGE_URL, using TMDB_RESULT.poster_path
_constructImageURL() {
  local p="$(echo "$TMDB_RESULT" | jq -r '.poster_path // .backdrop_path')"
  local s="w185"
  TMDB_IMAGE_URL="https://image.tmdb.org/t/p/${s}/${p}"
}

# Check return code of curl-ing $1, returns true if code is in [200 301 302], else false
_validateURL() {
  local retCode
  retCode="$(curl -s -L -o /dev/null -w '%{http_code}' --max-time 5 "$1" 2>/dev/null)"
  case "$retCode" in
  200 | 301 | 302)
    return 0
    ;;
  *)
    return 1
    ;;
  esac
}

# Call _validateURL on each entry in TMDB_RESULT
# _filterResultsByURL() {
#   local input="$1"
#   local type="$2"
#   local season="${3:-1}"
#   local episode="${4:-1}"
#
#   jq -c '.results[]' <<<"$input" |
#     while IFS= read -r entry; do
#       local id media_type url
#
#       id="$(jq -r '.id' <<<"$entry")"
#       media_type="$(jq -r '.media_type' <<<"$entry")"
#
#       # skip people early
#       [[ "$media_type" == "person" ]] && continue
#
#       url="$(_urlConstruct_FromArgs "$media_type" "$id" "$season" "$episode")"
#
#       if _validateURL "$url"; then
#         printf '%s\n' "$entry"
#       fi
#     done |
#     jq -s '{results: .}'
# }

# Formats given arguments into embed url
_urlConstruct_FromArgs() {
  local type="$1"
  local id="$2"
  local season="${3:-1}"
  local episode="${4:-1}"

  case "$type" in
  tv)
    echo "$VIDSRC_BASE/$type/$id/$season-$episode"
    ;;
  movie)
    echo "$VIDSRC_BASE/$type/$id"
    ;;
  *)
    return 1
    ;;
  esac
  return 0
}

# Update $TMDB_EMBED_URL, using URL Construct vars
_constructEmbedURL() {
  local type args
  if [[ -z "$TMDB_CACHE_QUERY" ]]; then
    if ! _curlID; then
      _notify -a ct -e "Failed to curl. ID = $TMDB_ID_SELECTED | TYPE = $TMDB_TYPE" && exit 1
    else
      type="$TMDB_TYPE"
    fi
  else
    type="$(cat "$TMDB_CACHE_QUERY" | jq -r --argjson id "$TMDB_ID_SELECTED" '.results[] | select(.id == $id) | .media_type')"
  fi
  TMDB_EMBED_URL="$(_urlConstruct_FromArgs "$type" "$TMDB_ID_SELECTED" "$TMDB_EPISODE_SELECTED" "$TMDB_SEASON_SELECTED")"
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

# Attempts to _curlID, constructs type-based statString for _notify. If -t 1, kitten icat $TMDB_IMAGE_URL
_statID() {
  if ! _curlID; then
    _notify -a ct -e "Could not find result for $TMDB_ID_SELECTED" && return 1
  fi

  local statString

  # Returns empty if missing next_episode_to_air property
  _nextAir() {
    local nextData="$(echo "$TMDB_RESULT" | jq '.next_episode_to_air')"
    [[ -z "$nextData" || "$nextData" = "null" ]] && echo "" && return 0
    echo "Next Episode: $(echo "$nextData" | jq -r '"\(.air_date) [\(.name)]"')"
  }

  # Returns empty if missing .seasons property
  _statTV_Seasons() {
    ! $TMDB_TV_STAT_INCLUDE_SEASONS && echo "" && return 0
    local seasons scount entry
    local finalString=()
    seasons="$(echo "$TMDB_RESULT" | jq '.seasons')"
    scount="$(echo "$seasons" | jq 'length')"
    for ((i = 0; i < "$scount"; i++)); do
      entry="$(echo "$seasons" | jq --argjson index "$i" '.[$index]')"
      finalString+=(
        "$(
          cat <<EOF

[$(echo "$entry" | jq -r '.name')]
ID: $(echo "$entry" | jq -r '.id')
Episode Count: $(echo "$entry" | jq -r '.episode_count')
EOF
        )
      ")
    done
    echo -e "${finalString[*]}"
  }

  case "$TMDB_TYPE" in
  tv)
    statString="$(
      cat <<EOF
[TV Show]
ID: $TMDB_ID_SELECTED
Name: $(echo "$TMDB_RESULT" | jq -r '.name')
Season Count: $(echo "$TMDB_RESULT" | jq -r '.number_of_seasons // "unknown"')
Episode Count: $(echo "$TMDB_RESULT" | jq -r '.number_of_episodes // "unknown"')
First Aired: $(echo "$TMDB_RESULT" | jq -r '.first_air_date // "unknown"')
Last Aired: $(echo "$TMDB_RESULT" | jq -r '.last_air_date // "unknown"')
Status: $(echo "$TMDB_RESULT" | jq -r '.status // "unknown"')
$(_statTV_Seasons)
$(_nextAir)
EOF
    )"
    [[ -t 1 ]] && {
      _constructImageURL
      kitty +kitten icat --align left "$TMDB_IMAGE_URL"
    }
    _notify -a ct "$statString"
    ;;

  movie)
    statString="$(
      cat <<EOF
[Movie]
ID: $TMDB_ID_SELECTED
Name: $(echo "$TMDB_RESULT" | jq -r '.name // .title')
Released: $(echo "$TMDB_RESULT" | jq -r '.release_date // "unknown"')
Duration: $(echo "$TMDB_RESULT" | jq -r '.runtime // "unknown"')
EOF
    )"
    [[ -t 1 ]] && {
      _constructImageURL
      kitty +kitten icat --align left "$TMDB_IMAGE_URL"
    }
    _notify -a ct "$statString"
    ;;
  esac

  return 0
}

# If $NEXT_MODE is set, swallow it into $MODE. $NEXT_MODE is then set to $1
_swallowNextMode() {
  [[ -z "$NEXT_MODE" ]] && return 1
  MODE="$NEXT_MODE"
  NEXT_MODE="$1"
  return 0
}

[[ "$MODE" != "QUERY" && $TMDB_DO_STAT ]] && MODE="STAT"
while $LOOP; do

  case "$MODE" in

  QUERY)
    if ! _curlQuery; then
      _notify -a ct "No results found for: $TMDB_QUERY ($TMDB_TYPE)" && exit 1
    else
      #NOTE: Filter works but is slow
      # TMDB_RESULT="$(_filterResultsByURL "$TMDB_RESULT" "$TMDB_TYPE" "$TMDB_SEASON_SELECTED" "$TMDB_EPISODE_SELECTED")"
      _cacheQuery
      TMDB_ID_SELECTED="$(
        echo "$TMDB_RESULT" |
          jq -r --arg type "$TMDB_TYPE" '
      .results[]
      | select(.media_type != "person")
      | select($type == "" or .media_type == $type)
      | "(\(.id)) \(.name // .title) [\(.media_type)] [\(.release_date // .first_air_date // "unknown")]"
    ' |
          wofi -d "${W_ARGS[@]}" |
          sed -E 's/^\(([^)]+)\).*/\1/'
      )"
      [[ -z "$TMDB_ID_SELECTED" ]] && exit 0
      #TODO: Replace with some other constructor function that can be reused in other $MODE(s)
      TMDB_TYPE="$(echo "$TMDB_RESULT" | jq -r --argjson id "$TMDB_ID_SELECTED" '.results[] | select(.id == $id) | .media_type')"

      [[ -z "$NEXT_MODE" ]] && NEXT_MODE="LAUNCH"
      _swallowNextMode
    fi
    ;;

  STAT)
    if ! _statID; then
      exit 1
    fi

    #TEST:
    echo "$TMDB_RESULT" | jq >"$HOME/test/${TMDB_ID_SELECTED}_${TMDB_TYPE}_stat_result.json"

    if ! _swallowNextMode; then
      LOOP=false
    fi
    ;;

  LAUNCH)
    #TEST:
    echo "$TMDB_RESULT" | jq >"$HOME/test/${TMDB_ID_SELECTED}_${TMDB_TYPE}_result.json"

    _constructEmbedURL
    firefox --new-window "$TMDB_EMBED_URL" &

    if ! _swallowNextMode; then
      LOOP=false
    fi
    ;;

  esac
done
