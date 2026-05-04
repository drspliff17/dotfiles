#!/usr/bin/env fish

function mangolauncher
    bash -lc "bash_mangolauncher $argv &"
    return 0
end
