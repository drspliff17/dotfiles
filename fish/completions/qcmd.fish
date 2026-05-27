function __qcmd_commands
    jq -r '.[].command' ~/.config/quickshell/data/cmd.json | sort -u
end

function __qcmd_resolve
    set -l cmd (commandline -opc)[2]

    jq -r --arg a "$cmd" '
        .[]
        | select(.command == $a or (.alias | index($a)))
        | .command
    ' ~/.config/quickshell/data/cmd.json
end

function __config_keys
    jq -r 'keys[]' ~/.config/quickshell/config.json
end

complete -c qcmd -n "test (count (commandline -opc)) -eq 1" \
    -a "(__qcmd_commands)" \
    -f

complete -c qcmd -n '
  test (count (commandline -opc)) -eq 2;
  and test (__qcmd_resolve) = set_configProperty
' \
    -a "(__config_keys)" \
    -f

complete -c qcmd -n '
    test (count (commandline -opc)) -eq 3;
    and test (__qcmd_resolve) = set_configProperty
' \
    -a "(__config_keys)" \
    -f

complete -c qcmd -n '
    test (count (commandline -opc)) -eq 2;
    and test (__qcmd_resolve) = get_configProperty
' \
    -a "(__config_keys)" \
    -f
