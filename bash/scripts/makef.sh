#!/usr/bin/env bash

OPT="$1"
VALUE="$2"
EXT="${OPT##*.}"
CONTENT=""

_chmod() {
  local file="$1"
  [[ ! -f "$file" ]] && return 1
  chmod +x "$file" && return 0
}

#TODO: IMPLEMENT THIS SOMETIME
# _odinCompileBuilder() {
#   local sourcePath="$1" outputBin="$2" linkPath="$3" cur="$PWD"
#   cat <<EOF
# #!/usr/bin/env bash
#
# SP="$sourcePath"
# OB="$outputBin"
# LP="$linkPath"
#
# echo "Compiling now ... "
# echo "Would be compiling $SP to $OB"
# #time odin build "$SP" -out:"$OB"
#
# #[[ -e "$LP" ]] && rm "$LP" && echo "[Removed Symlink]"
# #ln -s "$cur/$OB" "$LP" && echo "[Created Symlink: $LP]"
# echo "Would be linking $cur/$OB to $LP"
#
# EOF >"$cur/compile.sh"
#   chmod +x "$cur/compile.sh"
# }

case "$OPT" in
odin)
  [[ -z "$VALUE" ]] && {
    read -rp "Enter name for new Odin Project: " name
    [[ -z "$name" ]] && echo "[ABORTED]" && exit 1
    VALUE="$name"
  }

  [[ -d "$VALUE" ]] && echo "Directory Already Exists: $VALUE" && exit 1
  mkdir -p "$VALUE" && mkdir -p "$VALUE/src"
  echo -e "package main\n\nmain :: proc() {}" >"$PWD/$VALUE/src/main.odin"
  echo "Created Odin Project" && exit 0
  ;;

# ob | odin-build)
#   [[ -f "$PWD/compile.sh" ]] && {
#     read -rp "Build script already exists, would you like to overwrite it? [y/N]: " confirm
#     [[ ! "$confirm" =~ ^[Yy]$ ]] && echo "[ABORTED]" && exit 1
#   }
#   _odinCompileBuilder "$PWD/src" "test" "$HOME/.local/bin/test"
#   exit 0
#   ;;

esac

case "$EXT" in
sh)
  CONTENT="#!/usr/bin/env bash"
  trap '_chmod $OPT' EXIT
  ;;
esac

echo "$CONTENT" >"$OPT"
