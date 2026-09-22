function __obang_complete_bangs
    set -l prefix (commandline -ct)
    obang __complete-bangs "$prefix"
end

function __obang_at_root
    set -l words (commandline -opc)
    test (count $words) -eq 1
end

function __obang_wants_bang
    set -l words (commandline -opc)

    if test (count $words) -lt 2
        return 1
    end

    switch $words[2]
        case -c cmd --command -g get --get
            return 0
    end

    return 1
end

function __obang_after_completions
    set -l words (commandline -opc)
    test (count $words) -ge 2; and test "$words[2]" = completions
end

complete -c obang -f

complete -c obang -n '__obang_at_root' -a 'cmd'         -d 'Resolve and open a bang'
complete -c obang -n '__obang_at_root' -a 'runner'      -d 'Open the configured runner as a bang input box'
complete -c obang -n '__obang_at_root' -a 'browse'      -d 'Browse and search bangs in a runner menu'
complete -c obang -n '__obang_at_root' -a 'search'      -d 'Fuzzy-search bang names'
complete -c obang -n '__obang_at_root' -a 'get'         -d 'Get a bang by trigger or alias'
complete -c obang -n '__obang_at_root' -a 'count'       -d 'Print the number of cached bangs'
complete -c obang -n '__obang_at_root' -a 'update'      -d 'Update the Kagi bang database'
complete -c obang -n '__obang_at_root' -a 'completions' -d 'Print shell completions'
complete -c obang -n '__obang_at_root' -a 'help'        -d 'Show help'

complete -c obang -n '__obang_at_root' -a '-c' -d 'Resolve and open a bang'
complete -c obang -n '__obang_at_root' -a '-r' -d 'Open a runner as a bang input box'
complete -c obang -n '__obang_at_root' -a '-b' -d 'Browse bangs in a runner menu'
complete -c obang -n '__obang_at_root' -a '-s' -d 'Fuzzy-search bang names'
complete -c obang -n '__obang_at_root' -a '-g' -d 'Get a bang by trigger or alias'
complete -c obang -n '__obang_at_root' -a '-n' -d 'Print the number of cached bangs'
complete -c obang -n '__obang_at_root' -a '-u' -d 'Update the Kagi bang database'
complete -c obang -n '__obang_at_root' -a '-h' -d 'Show help'

complete -c obang \
    -n '__obang_wants_bang' \
    -a '(__obang_complete_bangs)'

complete -c obang \
    -n '__obang_after_completions' \
    -a 'fish bash zsh' \
    -d 'Shell completions'
