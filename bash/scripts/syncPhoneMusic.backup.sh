#
# # Declarations
#
# # Used to temporarily mount Device storage, for file transfer
# TMP_PATH="$HOME/tmp_mnt_phone"
#
# SOURCE_PATH="$HOME/Music/Songs"
# DESTINATION="$TMP_PATH/Internal shared storage/Music/Songs"
#
# # Determines logic executed in _performTransfer
# MODE=""
#
# VERBOSE=0
#
# # Helpers
#
# # Ensure unmount && TMP_PATH removal
# _cleanup() {
#   fusermount -u "$TMP_PATH" 2>/dev/null
#   rm -rf "$TMP_PATH" && _log "Removed $TMP_PATH"
# }
#
# # Echo, only when VERBOSE == 1
# _log() {
#   [[ "$VERBOSE" -eq 1 ]] && echo "$1"
# }
#
# # Main logic function, operation based on MODE
# _performTransfer() {
#   mountpoint -q "$TMP_PATH" || {
#     echo "[ERROR] $TMP_PATH is not mounted" >&2
#     return 1
#   }
#   shopt -s nullglob
#   local dname fname
#   local dmissing=0
#   local fmissing=0
#
#   case "$MODE" in
#   "QUICK" | "DRY")
#     for directory in "$SOURCE_PATH"/*; do
#       [[ ! -d "$directory" ]] && _log "Skipping $directory: Not a directory" && continue
#       dname="$(basename "$directory")"
#       [[ ! -d "$DESTINATION/$dname" ]] && {
#         if [[ "$MODE" = "DRY" ]]; then
#           echo "Found missing directory: $directory"
#           ((dmissing++))
#           continue
#         else
#           cp -a "$directory" "$DESTINATION"
#           _log "Copied $directory to $DESTINATION" && continue
#         fi
#       }
#       for file in "$directory"/*.mp3; do
#         fname="$(basename "$file")"
#         [[ -f "$DESTINATION/$dname/$fname" ]] && _log "Skipping $file: File already exists at $DESTINATION/$dname" && continue
#         if [[ "$MODE" = "DRY" ]]; then
#           echo "Found missing file: $file"
#           ((fmissing++))
#           continue
#         else
#           cp -a "$file" "$DESTINATION/$dname"
#           _log "Copied $file to $DESTINATION/$dname"
#         fi
#       done
#     done
#     [[ "$MODE" = "DRY" ]] && {
#       echo "[Transfer Info] Missing Directories: $dmissing | Missing Files: $fmissing"
#     }
#     ;;
#   "WIPE")
#     _log "[Transfer Size: $(du -hs "$SOURCE_PATH" | cut -f1)]"
#     [[ "$DESTINATION" == "$TMP_PATH"* ]] || {
#       echo "[ERROR] DESTINATION escaped TMP_PATH. Killing now. Prevented deletion of: $DESTINATION" >&2
#       return 1
#     }
#     local files=("$SOURCE_PATH"/*)
#     [[ ${#files[@]} -eq 0 ]] && _log "[ERROR] No files to move!" && return 1
#     find "$DESTINATION" -mindepth 1 -delete && _log "$DESTINATION: REMOVED CONTENTS"
#     cp -a "${files[@]}" "$DESTINATION" || return 1
#     ;;
#   esac
#   return 0
# }
#
# # Init
# [[ ! -d "$SOURCE_PATH" ]] && echo "[ERROR] Source Path for transfer not found! Expected: $SOURCE_PATH" >&2 && exit 1
#
# # Parse Arguments
# while [[ "$#" -gt 0 ]]; do
#   case "$1" in
#   -v | --verbose)
#     shift
#     VERBOSE=1
#     ;;
#   -q | --quick)
#     shift
#     [[ -n "$MODE" ]] && echo "[ERROR] Can only use one MODE" >&2 && exit 1
#     MODE="QUICK"
#     ;;
#   -w | --wipe)
#     shift
#     [[ -n "$MODE" ]] && echo "[ERROR] Can only use one MODE" >&2 && exit 1
#     MODE="WIPE"
#     ;;
#   esac
# done
# [[ -z "$MODE" ]] && MODE="DRY"
#
# # Main Execution
# mkdir -p "$TMP_PATH" && _log "Created temporary directory $TMP_PATH"
# trap _cleanup EXIT
# jmtpfs "$TMP_PATH" && _log "Mounted Device" || {
#   echo "[ERROR] jmtpfs failed to mount" >&2 && exit 1
# }
# [[ ! -d "$DESTINATION" ]] && {
#   echo "[ERROR] Destination Path for transfer not found! Expected: $DESTINATION" >&2
#   exit 1
# }
# echo "Beginning operation. Ensure stable connection until process is complete. This may take some time..."
# _performTransfer || {
#   echo "[ERROR] _performTransfer returned an error. Check state of $DESTINATION contents" >&2 && exit 1
# }
# _log "Device Unmounted"
# echo "[FINISHED]"
#!/usr/bin/env bash
