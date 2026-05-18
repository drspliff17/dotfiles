#!/usr/bin/env bash

_init() {
  [[ -z "$ROOT_DIR" || -z "$ENTRY_DIR" || -z "$DB" ]] && {
    return 1
  }
  [[ -f "$DB" ]] && _dbBackup
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

_dbBackup() {
  local ts backup_dir count

  ts="$(date -u +"%Y%m%dT%H%M%SZ")"
  backup_dir="$BACKUP_DIR/$ts"

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

  echo "[OK] backup created: $backup_dir"
}

# Reassigns DB entry's id, based on index
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

# Delete entry from DB via ID
_dbDeleteEntry() {
  local target_id="$1"

  [[ -z "$target_id" ]] && return 1

  local filepath
  filepath="$(yq -r ".data[] | select(.id == ($target_id | tonumber)) | .filepath" "$DB")"

  [[ -z "$filepath" || "$filepath" == "null" ]] && {
    echo "No entry found for id $target_id"
    return 1
  }

  rm -f "$filepath"

  yq -i "
  .data |= map(select(.id != ($target_id | tonumber)))
  " "$DB"

  _notify -a ct "Deleted Entry: $filepath"

  return 0
}

# Update modified time on manifest entry-entry
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

# Add entry to DB (and create entry file)
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

_dbInteractiveMenu() {
  local imenu_state="Root"
  local w_args=()
  local selection entryID

  _optValid() {
    case "$1" in
    Add | Edit | Delete | Backup)
      return 0
      ;;
    esac
    return 1
  }

  while true; do
    case "$imenu_state" in
    Root)
      WOFI_PROMPT="Select Option"
      WOFI_WIDTH="10%"
      WOFI_HEIGHT="20%"
      WOFI_CONFIG="$HOME/.config/wofi/center-align-config"
      _construct w_args
      selection="$(echo -e "Add\nEdit\nDelete\nBackup" | wofi -d "${w_args[@]}")"
      _optValid "$selection" || return 1
      imenu_state="$selection"
      ;;

    Add)
      WOFI_PROMPT="Enter Title (Optional)"
      WOFI_WIDTH="30%"
      WOFI_HEIGHT="10%"
      _construct w_args
      selection="$(wofi -d "${w_args[@]}")"
      entryID="$(_dbAddEntry "$selection")"
      kitty fish -c "n $ENTRY_DIR/entry_$entryID.md"
      _dbTouchEntry "$entryID"
      return 0
      ;;
    esac
  done
  return 0
}
