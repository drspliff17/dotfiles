# Fish completions for the `sm` music sync command.

function __sm_music_directories
    set -l root "$HOME/Music/Songs"
    test -d "$root"; or return

    for path in "$root"/*/
        test -d "$path"; or continue
        set -l relative (string replace -- "$root/" '' "$path")
        set relative (string trim -r -c / -- "$relative")
        printf '%s\t%s\n' "$relative" 'Music directory'
    end
end

function __sm_directory_argument
    set -l tokens (commandline -opc)
    for token in $tokens
        contains -- "$token" -s --specific -r --revparse; and return 0
    end
    return 1
end

# Modes and general options.
complete -c sm -f
complete -c sm -s h -l help -d 'Show help and exit'
complete -c sm -s q -l quick -d 'Push MP3 files missing from the phone'
complete -c sm -s w -l wipe -d 'Replace the phone destination with the source tree'
complete -c sm -s s -l specific -r -d 'Push missing MP3s from selected directories'
complete -c sm -s r -l revparse -d 'Remove phone files absent from the PC; directories are optional'
complete -c sm -s c -l count -d 'Count MP3s and list phone-only paths at the default locations'
complete -c sm -s v -l verbose -d 'Print skipped, pushed, and deleted files'
complete -c sm -s f -l from -r -F -d 'Set the PC source directory'
complete -c sm -s t -l to -r -d 'Set the phone destination path'

# -s and -r accept source-relative directory names or explicit paths.
complete -c sm -n __sm_directory_argument -a '(__sm_music_directories)'
complete -c sm -n __sm_directory_argument -F
