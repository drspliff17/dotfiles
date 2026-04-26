#!/usr/bin/env bash

# NOTE:
# - Can get/set settings (execTags has own interface)
# - Can generate user service units from aforementioned settings

# TODO:
#  Begin implementing primary modes, and designing main interface
#  -> possibly having an interactive one?
#  Need logic for generating theme (extended to both manual mode, and automatic mode)

themectl() {

  # Definitions
  local configPath="$HOME/.config/themectl"
  local relative_configFile="/config.yml"
  local relative_themeDir="/themes"

  local systemdServicePath="$HOME/.config/systemd/user"
  local relative_sdServiceFile="/themectl_exec.service"
  local relative_sdTimerFile="/themectl_exec.timer"

  # Variable Def
  local mode=""
  local submode=""
  local arguments=()

  # Helpers

  # Returns value of setting, if it exists
  _getSetting() {
    local key="$1"
    [[ -z "$key" ]] && echo "[ERROR] _getSetting: invalid usage: requires key" >&2 && return 1

    local file="$configPath$relative_configFile"
    [[ ! -f "$file" ]] && echo "[ERROR] _getSetting: config file not found, expected: $file" >&2 && return 1

    local query="$key"
    local result
    result=$(yq -r "
      .settings[]
      | select(has(\"${query%%.*}\"))
      | .${query}
    " "$file" 2>/dev/null)

    [[ -z "$result" || "$result" = "null" ]] && echo "[ERROR] _getSetting: invalid key: $key" >&2 && return 1
    echo "$result"
    return 0
  }

  # Set value of setting, using _getSetting to validate input key
  _setSetting() {
    local key="$1"
    local newValue="$2"
    local file="$configPath$relative_configFile"

    [[ -z "$key" || -z "$newValue" ]] && echo "[ERROR] _setSetting: invalid usage: expected <setting_key> <setting_value>" >&2 && return 1
    [[ ! -f "$file" ]] && echo "[ERROR] _setSetting: config file not found! Expected path: $configPath$relative_configFile" >&2 && return 1

    if ! _getSetting "$key" >/dev/null; then
      return 1
    fi

    if [[ "$key" == *.* ]]; then
      local root="${key%%.*}"
      local sub="${key#*.}"

      yq e -i "
        (.settings[] | select(has(\"$root\")) | .$root.$sub) = \"$newValue\"
      " "$file"
    else
      yq e -i "
        (.settings[] | select(has(\"$key\")) | .$key) = \"$newValue\"
      " "$file"
    fi
  }

  # Manage settings.execTags - Add, Remove, Has (Query, string-boolean return)
  _manageExecTag() {
    local m="$1"
    local tag="$2"
    local file="$configPath$relative_configFile"

    [[ -z "$m" ]] && echo "[ERROR] _manageExecTag: invalid usage: expected mode" >&2 && return 1
    [[ -z "$tag" ]] && echo "[ERROR] _manageExecTag: expected tag" >&2 && return 1

    case "$m" in
    add | a)
      if [[ "$(_manageExecTag has "$tag")" = "true" ]]; then
        echo "[ERROR] _manageExecTag: tag already exists: $tag" >&2 && return 1
      fi
      yq e -i '
        (.settings[] | select(has("execTags")) | .execTags)
        |= (. + ["'"$tag"'"])
      ' "$file"
      ;;

    remove | r)
      if [[ "$(_manageExecTag has "$tag")" = "false" ]]; then
        echo "[ERROR] _manageExecTag: tag does not exists: $tag" >&2 && return 1
      fi
      yq e -i '
        (.settings[] | select(has("execTags")) | .execTags)
        |= map(select(. != "'"$tag"'"))
      ' "$file"
      ;;

    has | h)
      yq e '
        (.settings[]
        | select(has("execTags"))
        | .execTags[]
        ) == "'"$tag"'"
      ' "$file"
      ;;

    *)
      echo "[ERROR] _manageExecTag: unknown mode: $m" >&2 && return 1
      ;;
    esac
    return 0
  }

  _manageThemeTag() {
    local m="$1"
    local tag="$2"
    local file="$3"

    [[ -z "$m" ]] && echo "[ERROR] _manageThemeTag: expected mode" >&2 && return 1
    [[ -z "$tag" ]] && echo "[ERROR] _manageThemeTag: expected tag" >&2 && return 1
    [[ -z "$file" ]] && echo "[ERROR] _manageThemeTag: expected file" >&2 && return 1

    case "$m" in
    add | a)
      if [[ "$(_manageThemeTag has "$tag" "$file")" = "true" ]]; then
        echo "[ERROR] tag already exists: $tag" >&2 && return 1
      fi
      yq e -i '
        .tags |= (. + ["'"$tag"'"])
      ' "$file"
      ;;

    remove | r)
      if [[ "$(_manageThemeTag has "$tag" "$file")" = "false" ]]; then
        echo "[ERROR] tag does not exist: $tag" >&2 && return 1
      fi
      yq e -i '
        .tags |= map(select(. != "'"$tag"'"))
      ' "$file"
      ;;

    has | h)
      yq e '
        (.tags[]
        | select(. == "'"$tag"'")
        ) == "'"$tag"'"
      ' "$file"
      ;;

    *)
      echo "[ERROR] unknown mode: $m" >&2 && return 1
      ;;
    esac
  }

  # Generate default .yml config file
  _generateDefaultConfig() {
    cat <<EOF >"$configPath$relative_configFile"
version: 0.1

settings:
  - userService:
      enabled: "false"
      onBoot: "false"
      onBootSec: "30min"
      interval: "30min"
      exec: "unset"
      path: "$systemdServicePath"
  - exec: "unset"
  - execTags: []

EOF
    return 0
  }

  # Generate User Service Files [service, timer] - using _getSetting to retrieve relevant values
  _generateUserService() {
    mkdir -p "$systemdServicePath"
    case "$1" in
    service)
      local serviceExecStart="$(_getSetting userService.exec)"
      [[ "$serviceExecStart" = "unset" ]] && echo "[ERROR] _generateUserService: Cannot create Service Unit file: exec unset" >&2 && return 1
      cat <<EOF >"$systemdServicePath$relative_sdServiceFile"
[Unit]
Description="Executes themectl userService.exec setting"

[Service]
Type=oneshot
ExecStart="$serviceExecStart"
EOF
      ;;
    timer)
      local serviceOnBoot="$(_getSetting userService.onBoot)"
      local serviceInterval="$(_getSetting userService.interval)"
      if [[ "$serviceOnBoot" == "true" ]]; then
        cat <<EOF >"$systemdServicePath$relative_sdTimerFile"
[Unit]
Description="Executes themectl user service at userService.interval"

[Timer]
OnUnitActiveSec=$serviceInterval
Persistent=false

[Install]
WantedBy=timers.target
EOF
        return 0
      else
        local serviceOnBootSec="$(_getSetting userService.onBootSec)"
        cat <<EOF >"$systemdServicePath$relative_sdTimerFile"
[Unit]
Description="Exectutes themectl user service at userService.onBootSec + userService.interval"

[Timer]
OnBootSec=$serviceOnBootSec
OnUnitActiveSec=$serviceInterval
Persistent=false

[Install]
WantedBy=timers.target
EOF
        return 0
      fi
      ;;
    esac
  }

  _removeUserServiceFiles() {
    rm "$systemdServicePath$relative_sdServiceFile" 2>/dev/null
    rm "$systemdServicePath$relative_sdTimerFile" 2>/dev/null
  }

  # Generates a new theme file
  _createThemeEntry() {
    local t_filepath="$1"
    local t_name="$2"
    local t_tags=("${@:3}")

    [[ -z "$t_filepath" || -z "$t_name" ]] && echo "[ERROR] _createThemeEntry: Invalid usage: expected <filepath> <name> [tags]" >&2 && return 1

    local t_file="$configPath$relative_themeDir/$t_name.yml"
    [[ -f "$t_file" ]] && {
      read -rp "[WARNING] Theme file already exists: $t_file - overwrite it? [Yy]:  " confirm
      [[ ! "$confirm" =~ ^[Yy]$ ]] && echo "Aborted" && return 1
    }
    cat <<EOF >"$t_file"
filepath: $t_filepath
tags:
$(for tag in "${t_tags[@]}"; do echo "  - $tag"; done)
EOF
    return 0
  }

  # Creates config directory (+themes dir) and default config.yml file
  _initConfig() {
    mkdir -p "$configPath$relative_themeDir"
    _generateDefaultConfig && echo "[INIT] Created config directory: $configPath [$relative_themeDir/ && $relative_configFile]"

    [[ "$(_getSetting userService.exec)" = "unset" ]] && {
      read -rp "[INIT] User Service: ExecStart unset. Enter it now, or hit enter to leave unset:  " conf_us_exec
      [[ -z "$conf_us_exec" ]] && conf_us_exec="unset" && echo "[WARNING] Value required in order to use User Service Control"
      _setSetting userService.exec "$conf_us_exec" && echo "[INIT] Setting: userService.exec = $conf_us_exec"
    }

    [[ "$(_getSetting exec)" = "unset" ]] && {
      read -rp "[INIT] Exec unset: Enter it now, or hit enter to leave unset:  " conf_exec
      [[ -z "$conf_exec" ]] && conf_exec="unset"
      _setSetting exec "$conf_exec" && echo "[INIT] Setting: exec = $conf_exec"
    }
    return 0
  }

  # Returns boolean, based on if relative_sdTimerFile is-active
  _userServiceStatus() {
    local status="$(systemctl --user is-active "$systemdServicePath$relative_sdTimerFile")"
    [[ "$status" = "inactive" ]] && return 1 || return 0
  }

  # Parse Arguments
  [[ "$#" -eq 0 ]] && echo "[ERROR] Expected Arguments. Use -h / help for information" >&2 && return 1
  while [[ "$#" -gt 0 ]]; do
    case "$1" in
    -a | add)
      [[ -n "$mode" ]] && echo "[ERROR] Cannot overwrite Mode once set, currently: $mode - attempted to set: add" >&2 && return 1
      shift
      mode="add"
      arguments+=("$@")
      break
      ;;
    -r | remove)
      [[ -n "$mode" ]] && echo "[ERROR] Cannot overwrite Mode once set, currently: $mode - attempted to set: remove" >&2 && return 1
      shift
      mode="remove"
      arguments+=("$@")
      break
      ;;
    -e | edit)
      [[ -n "$mode" ]] && echo "[ERROR] Cannot overwrite Mode once set, currently: $mode - attempted to set: edit" >&2 && return 1
      shift
      mode="edit"
      arguments+=("$@")
      break
      ;;
    -s | service)
      shift
      mode="service"
      case "$1" in
      start)
        submode="start"
        shift
        ;;
      stop)
        submode="stop"
        shift
        ;;
      enable)
        submode="enable"
        shift
        ;;
      disable)
        submode="disable"
        shift
        ;;
      remove)
        submode="remove"
        ;;
      "" | *)
        echo "[ERROR] Invalid Submode given: '$1' - Valid modes -> [ start stop enable disable remove ]" >&2 && return 1
        ;;
      esac
      arguments+=("$@")
      break
      ;;
    *)
      echo "[ERROR] Unknown argument/flag: $1" >&2 && return 1
      ;;
    esac
  done

  rm -r ~/.config/themectl #TEST:
  _removeUserServiceFiles

  # Init && Generate UserService Units
  [[ ! -f "$configPath$relative_configFile" ]] && _initConfig

  if [[ "$(_getSetting userService.enabled)" = "true" ]]; then
    [[ ! -f "$systemdServicePath$relative_sdServiceFile" ]] && {
      if _generateUserService service; then
        echo "[INFO] Generated Service Unit: $systemdServicePath$relative_sdServiceFile"
      else
        return 1
      fi
    }

    [[ ! -f "$systemdServicePath$relative_sdTimerFile" && -f "$systemdServicePath$relative_sdServiceFile" ]] && {
      if _generateUserService timer; then
        echo "[INFO] Generated Timer Unit: $systemdServicePath$relative_sdTimerFile"
      else
        return 1
      fi
    }
  fi

  # Execute Mode-based sequence
  case "$mode" in
  add)
    # _createThemeEntry "${arguments[0]}" "${arguments[1]}"
    ;;
  esac
}
