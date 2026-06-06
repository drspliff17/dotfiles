#!/usr/bin/env bash

#TODO: Implement a per season/episode stat (?)

#TODO: Refactor to allow passing from query to stat, with prompt before launch

#TODO: build interactive menu prompts for when required args are not provided (or as a mode?)

#TODO: Cache last query, make mode to jump back to last stat'd ID
# Cache curled images when selecting an id for the first time

#TODO: Cache recently stat'd too, can check this before making curl as that is probably quicker

#TODO: Create a state file that can track things such as the $VIDSRC_BASE

#TODO: Add Vidsrc 404 filter to results

#TODO: Create log system, which could then be parsed for history (or just make a history thing by itself)

## Dependancies

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

## Main Declarations

# Main Ctl vars
MODE=""
NEXT_MODE=""
USE_CACHE=true
LOOP=true

# Const vars

VIDSRC_BASE="https://vidsrc-embed.ru/embed"
TMDB_T="$(tr -d '\r\n ' <"$HOME/dev/data/env/.tmdb.env")"
SYNC_SCRIPT="$HOME/dev/python/watchstuff_sync_db.py"

TMDB_CACHE_DIR="$HOME/.cache/watchstuff"
TMDB_CACHE_DB="$TMDB_CACHE_DIR/database.json"
TMDB_CACHE_LOG="$TMDB_CACHE_DIR/watchstuff.log"
TMDB_CACHE_RECENT_STAT="$TMDB_CACHE_DIR/recent_stat.json"
TMDB_CACHE_HISTORY="$TMDB_CACHE_DIR/history.json"

# Parameter vars

TMDB_QUERY=""

TMDB_RESULT=""
TMDB_RESULT_COUNT=0
TMDB_RESULT_IDS=()

TMDB_DO_STAT=false
TMDB_TV_STAT_INCLUDE_SEASONS=true

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
  # [[ -e "$TMDB_CACHE_QUERY" ]] && rm "$TMDB_CACHE_QUERY"
  echo "ENDED"
}

trap '_cleanup' EXIT

## Cache Dir Helpers

_cacheInit() {
  cat <<EOF >"$TMDB_CACHE_RECENT_STAT"
{
  "data": []
}
EOF

  #   cat <<EOF >"$TMDB_CACHE_HISTORY"
  # {
  #   "data": []
  # }
  # EOF

}

# Create entry into log file
_logAdd() {
  local msg="$1" level="${2:-INFO}" file="${3:-$TMDB_CACHE_LOG}" ts="$(date)"
  [[ -z "$msg" ]] && _notify "Log called, but no content given. You silly spoon." && return 1
  echo "[$ts] - ($level) :: $msg" >>"$file"
}

# Ensures a max number of entries
_cacheStatPurge() {
  local max=50
  local min=25
  [[ "$(jq '.data | length')" -ge $max ]] && {
    #TODO: this + same for history
    return 0
  }
  return 1
}

# Append stat results to $TMDB_CACHE_RECENT_STAT
_cacheStat() {
  local tmp="$(mktemp)"
  jq --argjson entry "$TMDB_RESULT" '.data += [$entry]' "$TMDB_CACHE_RECENT_STAT" >tmp && mv tmp "$TMDB_CACHE_RECENT_STAT"
  _logAdd "Cached $TMDB_ID_SELECTED to $TMDB_CACHE_RECENT_STAT" "STATUS"
}

## Main Helpers

# Update $TMDB_IMAGE_URL, using TMDB_RESULT.poster_path
_constructImageURL() {
  local p="$(echo "$TMDB_RESULT" | jq -r '.poster_path // .backdrop_path')"
  local s="w185"
  TMDB_IMAGE_URL="https://image.tmdb.org/t/p/${s}/${p}"
}

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

# Sets $TMDB_EMBED_URL using _urlConstruct_FromArgs
_constructEmbedURL() {
  TMDB_EMBED_URL="$(_urlConstruct_FromArgs "$TMDB_TYPE" "$TMDB_ID_SELECTED" "$TMDB_EPISODE_SELECTED" "$TMDB_SEASON_SELECTED")"
}

# Updates $TMDB_RESULT, using $TMDB_ID_SELECTED and $TMDB_TYPE. Returns false if id is not found
_curlID() {
  [[ -z "$TMDB_ID_SELECTED" ]] && _notify -a ct -e "Requires ID to query" && exit 1
  [[ -z "$TMDB_TYPE" ]] && _notify -a ct -e "Requires Type to query" && exit 1

  TMDB_RESULT="$(curl -s \
    "https://api.themoviedb.org/3/${TMDB_TYPE}/${TMDB_ID_SELECTED}" \
    -H "Authorization: Bearer $TMDB_T" \
    -H "AcceptL application/json")"

  echo "$TMDB_RESULT" | jq -e '.id' >/dev/null 2>&1 || {
    _logAdd "_curlID: Failed to find: $TMDB_ID_SELECTED" "FAILED"
    return 1
  }
  _logAdd "_curlID: Found: $TMDB_ID_SELECTED" "SUCCESS"
  return 0
}

# Attempts to _curlID, constructs type-based statString for _notify. If -t 1, kitten icat $TMDB_IMAGE_URL
_statID() {
  if ! _curlID; then
    _notify -a ct -e "Could not find result for $TMDB_ID_SELECTED"
    _logAdd "_statID: No result found for: $TMDB_ID_SELECTED" "FAILED"
    return 1
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
    echo "$statString"
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
    echo "$statString"
    ;;
  esac

  return 0
}

# If $NEXT_MODE is set, swallow it into $MODE. $NEXT_MODE is then set to $1
_swallowNextMode() {
  [[ -z "$NEXT_MODE" ]] && return 1
  _logAdd "_swallowNextMode: Setting Mode: $NEXT_MODE" "STATUS"
  [[ -n "$1" ]] && _logAdd "_swallowNextMode: Setting Next Mode: $1" "STATUS"
  MODE="$NEXT_MODE"
  NEXT_MODE="$1"
  return 0
}

## Database Helpers

# Creates database, if it does not alreay exist
_dbInit() {
  [[ ! -f "$TMDB_CACHE_DB" ]] && {
    cat <<EOF >"$TMDB_CACHE_DB"
{
  "tv" : {
    "data": []
  },
  "movie" : {
    "data": []
  }
}
EOF
  }
}

#TODO: Upgrade to none positional-based args and add a echo mode so it may be used elsewhere

# Replaces _curlQuery
_dbQuery() {
  local qmode type query file
  local echoResult=false
  local found filter selected selID

  while [[ "$#" -gt 0 ]]; do
    case "$1" in
    -m | --mode)
      qmode="$2"
      shift 2
      ;;
    -q | --query)
      query="$2"
      shift 2
      ;;
    -t | --type)
      type="$2"
      shift 2
      ;;
    -e | --echo)
      echoResult=true
      shift
      ;;
    *)
      shift
      ;;
    esac
  done

  case "$type" in
  tv)
    filter='.tv.data'
    ;;
  movie)
    filter='.movie.data'
    ;;
  any)
    #NOTE: Temp remopved until solution to identifying type from mixed can be divined
    return 1
    # filter='.tv.data + .movie.data'
    ;;
  *)
    _logAdd "_dbQuery Invalid type given: $type" "ERROR"
    return 1
    ;;
  esac
  case "$qmode" in
  Wofi)
    found="$(jq -r "$filter | .[] | \"\(.id) - \(.title)\"" "$TMDB_CACHE_DB")"
    if [[ -n "$query" ]]; then
      found="$(printf '%s\n' "$found" | rg -i "$query")"
    fi
    selected="$(printf '%s\n' "$found" | wofi -d "${W_ARGS[@]}")"
    [[ -z "$selected" ]] && return 1
    selID="$(echo "$selected" | cut -f1 -d' ')"
    $echoResult && echo "$selected" && return 0
    TMDB_ID_SELECTED="$selID"
    TMDB_TYPE="$type"
    ;;
  Tty)
    #TODO:
    ;;
  *)
    return 1
    ;;
  esac
}

_dbRecents

# Main function to handle wofi interactive menu
_wofiInteractiveMenu() {
  local mode="menu"
  local w_args=()
  local type query selection
  local file="$TMDB_CACHE_DB"
  while true; do
    case "$mode" in
    menu)
      [[ -z "$type" ]] && mode="type" && continue
      [[ -z "$query" ]] && mode="query" && continue

      [[ "$type" = "tv" ]] && {
        [[ -z "$TMDB_SEASON_SELECTED" ]] && mode="season" && continue
        [[ -z "$TMDB_EPISODE_SELECTED" ]] && mode="episode" && continue
      }

      _dbQuery -t "$type" -q "$query" -m Wofi -f
      [[ -z "$TMDB_ID_SELECTED" ]] && return 1
      NEXT_MODE="LAUNCH" && return 0
      ;;

    type)
      _wofiConstructFromArgs w_args -p "What would you like to watch?" -w "10%" -l 2 -cf "$WOFI_C_CENTER"
      selection="$(echo -e "TV Series\nMovie" | wofi -d "${w_args[@]}")"
      case "$selection" in
      "TV Series") type="tv" ;;
      "Movie") type="movie" ;;
      *) return 1 ;;
      esac
      mode="menu"
      ;;

    season)
      #TODO:
      ;;

    episode)
      #TODO:
      ;;

    #TODO: Implement a view latest thing here, maybe like !latest !new or something
    query)
      _wofiConstructFromArgs w_args -p "Enter your search query." -w "40%" -h "5%" -cf "$WOFI_C_CENTER"
      query="$(wofi -d "${w_args[@]}")"
      [[ -z "$query" ]] && return 1
      # case "$query" in
      #   #NOTE: Put custom exception / rules thing here
      # esac
      mode="menu"
      ;;

    esac
  done
}

## Init
_dbInit
_cacheInit

## Arg Parsing
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
    MODE="LAUNCH" #TODO: Replace with arg to set launch so its not directly tied to mode being set
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

  -w | --wofi)
    MODE="WOFI"
    shift
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

while $LOOP; do

  case "$MODE" in

  WOFI)
    _wofiInteractiveMenu || exit 1
    if ! _swallowNextMode; then
      LOOP=false
    fi
    ;;

  QUERY)
    _logAdd "Entered Query Mode" "STATUS"

    _wofiConstructFromArgs W_ARGS -p "Enter Search Query" -cf "$WOFI_C_CENTER" -w "40%" -h "5%"
    _dbQuery -m "Wofi" -t "$TMDB_TYPE" -q "$TMDB_QUERY" || exit 1

    [[ -z "$NEXT_MODE" ]] && NEXT_MODE="LAUNCH"
    _swallowNextMode
    ;;

  STAT)
    if ! _statID; then
      exit 1
    fi
    _cacheStat "$TMDB_RESULT"

    if ! _swallowNextMode; then
      LOOP=false
    fi
    ;;

  # Constructs URL for TMDB_* Variables, launches firefox
  LAUNCH)
    _constructEmbedURL
    firefox --new-window "$TMDB_EMBED_URL" &

    [[ -z "$TMDB_RESULT" ]] && {
      if ! _statID; then
        exit 1
      fi
      _cacheStat "$TMDB_RESULT"
    }

    if ! _swallowNextMode; then
      LOOP=false
    fi
    ;;

  esac
done
