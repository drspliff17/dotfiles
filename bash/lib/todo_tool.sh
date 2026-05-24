#!/usr/bin/env bash

#TODO: Include _dbConfirmationPrompt into _dbDeleteEntry if selected entry is not an empty file
#TODO: Add title length checking / concat -> make self-adjusting WOFI_LINES as used in wofi_command_launcher.sh

_init() {
  [[ -z "$ROOT_DIR" || -z "$ENTRY_DIR" || -z "$DB" ]] && {
    return 1
  }
  [[ -f "$DB" ]] && _dbCreateBackup
  mkdir -p "$ROOT_DIR"
  mkdir -p "$ENTRY_DIR"
  mkdir -p "$LOG_DIR"
  mkdir -p "$BACKUP_DIR"
  cat <<EOF >"$DB"
data: []
EOF
  return 0
}

_foundFiles() {
  [[ ! -d "$ROOT_DIR" ]] && return 1
  [[ ! -d "$ENTRY_DIR" ]] && return 1
  [[ ! -d "$LOG_DIR" ]] && return 1
  [[ ! -d "$BACKUP_DIR" ]] && return 1
  [[ ! -f "$DB" ]] && return 1
  return 0
}

# Independantly Handles Confirmation Menu, Prompt String && Menu Opts can be overwritten with $1 && $2 respectively
_dbConfirmationPrompt() {
  local a=()
  local opts="${2:-Yes\nNo}"

  WOFI_PROMPT="${1:-Are You Sure?}"
  WOFI_WIDTH="5%"
  WOFI_LINES="${#opts[@]}"
  _construct a
  local v="$(echo -e "$opts" | wofi -d "${a[@]}")"
  case "$v" in
  Yes)
    return 0
    ;;
  *)
    return 1
    ;;
  esac
}

# Reassigns id for all entries, renaming entry files accordingly
_dbReindex() {
  local tmp
  tmp=$(mktemp)

  echo "data: []" >"$tmp"

  yq -o=json '.data[]' "$DB" | jq -c '.' | while read -r entry; do
    local old_path new_id new_path

    old_path=$(echo "$entry" | jq -r '.filepath')

    new_id=$(yq '.data | length' "$tmp")
    new_path="$ENTRY_DIR/entry_${new_id}.md"

    if [[ -f "$old_path" && "$old_path" != "$new_path" ]]; then
      mv "$old_path" "$new_path"
    fi

    entry=$(
      echo "$entry" | jq \
        --arg id "$new_id" \
        --arg path "$new_path" '
        .id = ($id | tonumber)
        | .filepath = $path
      '
    )

    yq -i ".data += [$entry]" "$tmp"
  done

  mv "$tmp" "$DB"
}

# Create a (timestamped and sha256 hashed) backup in $BACKUP_DIR. Optionally prefix backup_dir with $1
_dbCreateBackup() {
  local ts backup_dir count
  local backup_dir_prefix="$1"

  ts="$(date -u +"%Y%m%dT%H%M%SZ")"
  backup_dir="$BACKUP_DIR/$ts"
  [[ -n "$backup_dir_prefix" ]] && backup_dir="$BACKUP_DIR/$backup_dir_prefix.$ts"

  mkdir -p "$backup_dir/entries"
  mkdir -p "$backup_dir/logs"

  cp "$DB" "$backup_dir/db.yml"

  shopt -s nullglob
  cp "$ENTRY_DIR"/entry_*.md "$backup_dir/entries/"
  shopt -u nullglob

  cp "$LOG_DIR"/* "$backup_dir/logs/" 2>/dev/null || true

  count=$(yq '.data | length' "$DB")

  find "$ENTRY_DIR" -maxdepth 1 -type f -name "entry_*.md" |
    sort >"$backup_dir/file_index.txt"

  sha256sum "$DB" >"$backup_dir/db.sha256"

  cat >"$backup_dir/manifest.txt" <<EOF
timestamp: $ts
entries: $count
backup_dir: $backup_dir
EOF

  _notify -a ct "[OK] Backup Created (E: $count): $backup_dir"
}

# Handle Wofi menu for Deleting Backup
_dbDeleteBackup() {
  shopt -s nullglob
  local backups=("$BACKUP_DIR"/*)
  local backup_count="${#backups[@]}"
  shopt -u nullglob

  [[ $backup_count -eq 0 ]] && _notify -a ct "No backups in $BACKUP_DIR" && return 1

  WOFI_PROMPT="Select Backup To Delete"
  WOFI_WIDTH="15%"
  WOFI_LINES="$backup_count"
  WOFI_CONFIG="$WOFI_C_CENTER"
  _construct w_args

  local selection="$(
    for b in "${backups[@]}"; do
      printf '%s\n' "${b##*/}"
    done | wofi -d "${w_args[@]}"
  )"
  [[ -z "$selection" ]] && return 1
  [[ ! -d "$BACKUP_DIR/$selection" ]] && _notify -a ct -e "No matching backup found for: $selection" && return 1
  if _dbConfirmationPrompt; then
    rm -r "$BACKUP_DIR/$selection"
    _notify "[OK] Backup Deleted: $BACKUP_DIR/$selection"
    return 0
  else
    return 1
  fi
}

# Add entry to DB (and create entry file), 'returns' the new entry ID
_dbAddEntry() {
  local title="${1:-Untitled}"
  local created="$(date +"%Y-%m-%dT%H:%M:%SZ")"
  local eid="$(yq '.data | length' "$DB")"
  local filepath="$ENTRY_DIR/entry_$eid.md"

  touch "$filepath"

  E_FILEPATH="$filepath" \
    E_TITLE="$title" \
    E_CREATED="$created" \
    E_EID="$eid" \
    yq -i '
    .data += [{
      "id": (env(E_EID) | tonumber),
      "filepath": env(E_FILEPATH),
      "title": env(E_TITLE),
      "creation_date": env(E_CREATED),
      "modified_date": env(E_CREATED),
      "tags": []
  }]
  ' "$DB"

  _notify -a ct "Created Entry: Title: $title - Path: $filepath"
  echo "$eid"
}

# Delete entry from DB via it's entry ID
_dbDeleteEntry() {
  local target_id="$1"
  [[ -z "$target_id" ]] && return 1

  local filepath
  filepath="$(yq -r ".data[] | select(.id == ($target_id | tonumber)) | .filepath" "$DB")"

  [[ -z "$filepath" || "$filepath" == "null" ]] && {
    _notify -e -a ct "No entry found for id $target_id"
    return 1
  }

  rm -f "$filepath"

  yq -i "
  .data |= map(select(.id != ($target_id | tonumber)))
  " "$DB"

  _notify -a ct "Deleted Entry: $filepath"
  return 0
}

# Handle Wofi menu for $ENTRY_DIR
_dbGetEntryMenu() {
  local selection
  local files
  local maxEntryCount=15

  shopt -s nullglob
  files=("$ENTRY_DIR"/entry_*.md)
  shopt -u nullglob

  [[ ${#files[@]} -eq 0 ]] && _notify -a ct "No files in $ENTRY_DIR" && return 1

  WOFI_LINES=${#files[@]}
  ((WOFI_LINES > maxEntryCount)) && WOFI_LINES=$maxEntryCount

  _construct w_args
  selection="$(
    for f in "${files[@]}"; do
      id="${f##*/}"
      id="${id#entry_}"
      id="${id%.md}"
      title="$(_dbGetEntryTitle "$id")"
      printf '%s - %s\n' "$title" "${f##*/}"
    done | wofi -d "${w_args[@]}"
  )"

  echo "$selection"
}

# Update entry modified time, via its entry ID
_dbTouchEntry() {
  local eid="$1"
  local modified="$(date +"%Y-%m-%dT%H:%M:%SZ")"
  E_EID="$eid" \
    E_MODIFIED="$modified" \
    yq -i '
      (.data[] | select(.id == (env(E_EID) | tonumber))).modified_date = env(E_MODIFIED)
    ' "$DB"
}

_dbGetEntryTitle() {
  yq -r ".data[] | select(.id == ${1}) | .title" "$DB"
}

# Handle Wofi menu for Interactive Edit
_dbInteractiveEdit() {
  WOFI_PROMPT="Pick Entry"
  WOFI_WIDTH="15%"
  WOFI_HEIGHT="35%"
  WOFI_CONFIG="$WOFI_C_CENTER"
  _construct w_args
  local files
  local maxLineCount=15

  shopt -s nullglob
  files=("$ENTRY_DIR"/entry_*.md)
  shopt -u nullglob

  [[ ${#files[@]} -eq 0 ]] && _notify -a ct "No entries inside $ENTRY_DIR" && return 1

  WOFI_LINES=${#files[@]}
  ((WOFI_LINES > maxLineCount)) && WOFI_LINES=$maxLineCount

  _construct w_args

  selection="$(
    for f in "$ENTRY_DIR"/entry_*.md; do
      id="${f##*/}"
      id="${id#entry_}"
      id="${id%.md}"
      title="$(_dbGetEntryTitle "$id")"
      printf '%s - %s\n' "$title" "${f##*/}"
    done | wofi -d "${w_args[@]}"
  )"
  [[ -z "$selection" ]] && return 1

  selection="${selection##* - }"

  kitty fish -c "n $ENTRY_DIR/$selection"

  id="${selection#entry_}"
  id="${id%.md}"
  _dbTouchEntry "$id"
  _notify -a ct "Updated manifest for $selection"
}

#NOTE: Interactive menu runs in loop. Returning 0 kills the loop, else _dbInteractiveMenu gets called again

# Handle Wofi menu for Full Interactive Edit
_dbInteractiveMenu() {
  local imenu_state="Root"
  local w_args=()
  local selection entryID
  local rootOpts=(
    "Add"
    "Delete"
    "Edit"
    "Backup"
  )

  _optValid() {
    case "$1" in
    Add | Delete | Edit | Backup | B_Create | B_Delete)
      return 0
      ;;
    esac
    return 1
  }

  WOFI_CONFIG="$WOFI_C_CENTER"
  while true; do
    case "$imenu_state" in
    Root)
      WOFI_PROMPT="Todo Tool Menu"
      WOFI_WIDTH="10%"
      WOFI_LINES="${#rootOpts[@]}"
      _construct w_args
      selection="$(echo -e "Add\nDelete\nEdit\nBackup" | wofi -d "${w_args[@]}")"
      _optValid "$selection" || return 0
      imenu_state="$selection"
      ;;

    Add)
      WOFI_PROMPT="Enter Title (default Untitled)"
      WOFI_WIDTH="15%"
      WOFI_HEIGHT="5%"
      WOFI_LINES=""
      _construct w_args
      selection="$(echo | wofi -d "${w_args[@]}")"
      entryID="$(_dbAddEntry "$selection")"
      kitty fish -c "n $ENTRY_DIR/entry_$entryID.md"
      _dbTouchEntry "$entryID"
      return 0
      ;;

    Delete)
      WOFI_PROMPT="Select Entry To Delete"
      WOFI_WIDTH="15%"
      WOFI_HEIGHT="35%"
      _construct w_args
      selection="$(_dbGetEntryMenu)"
      [[ -z "$selection" ]] && return 1
      selection="${selection##* - }"
      id="${selection#entry_}"
      id="${id%.md}"
      _dbDeleteEntry "$id"
      _dbReindex
      ;;
    Edit)
      WOFI_PROMPT="Pick Entry"
      WOFI_WIDTH="15%"
      WOFI_HEIGHT="35%"
      WOFI_CONFIG="$WOFI_C_CENTER"
      _construct w_args
      _dbInteractiveEdit || return 1
      ;;
    Backup)
      local menu_backup_opts=(
        "Create Backup"
        "Delete Backup"
        "Open"
      )
      WOFI_PROMPT="Select Backup Mode"
      WOFI_WIDTH="10%"
      WOFI_LINES="${#menu_backup_opts[@]}"
      _construct w_args
      selection="$(
        printf '%s\n' "${menu_backup_opts[@]}" | wofi -d "${w_args[@]}"
      )"
      case "$selection" in
      "Create Backup")
        imenu_state="B_Create"
        ;;
      "Delete Backup")
        imenu_state="B_Delete"
        ;;
      "Open")
        imenu_state="B_Open"
        ;;
      *)
        return 1
        ;;
      esac
      ;;
    B_Create)
      _dbCreateBackup
      return 0
      ;;
    B_Delete)
      _dbDeleteBackup || imenu_state="Backup"
      ;;
    B_Open)
      kitty yazi "~/.local/share/todo_tool/backups" &
      return 0
      ;;
    esac
  done
  return 0
}
