#!/usr/bin/env bash

repo_url="https://github.com/hyprwm/Hyprland.git"
repo_dir="$HOME/Repos/Hyprland"
targ_dir="$HOME/.local/share/hyprland-meta"
targ_file="meta/hl.meta.lua"
cloned_str="Cloned Missing Repo. Sparse set meta/lua. Run again to pull changes"
done_str="Moved $targ_file to $targ_dir from $repo_dir"

_notify() {
  if [[ ! -t 1 ]]; then
    notify-send -u normal -t 2000 -a center-text "$1" && return 0
  else
    echo "$1" && return 0
  fi
}

[[ ! -d "$targ_dir" ]] && mkdir -p "$targ_dir"
[[ ! -d "$repo_dir" ]] && {
  git clone --depth=1 --filter=blob:none --sparse "$repo_url" "$repo_dir"
  git -C "$repo_dir" sparse-checkout set meta/lua
  _notify "$cloned_str"
  exit 0
}

[[ ! -f "$repo_dir/.git/info/sparse-checkout" ]] && git -C "$repo_dir" sparse-checkout set meta/lua

git -C "$repo_dir" fetch --quiet origin main
local_head="$(git -C "$repo_dir" rev-parse HEAD)"
remote_head="$(git -C "$repo_dir" rev-parse origin/main)"
[[ "$local_head" == "$remote_head" ]] && {
  _notify "Hyprland meta already up to date" && exit 0
}

git -C "$repo_dir" reset --hard origin/main --quiet
git -C "$repo_dir" sparse-checkout reapply
cp "$repo_dir/meta/hl.meta.lua" "$targ_dir"
_notify "$done_str"
exit 0
