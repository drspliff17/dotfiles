#!/usr/bin/env fish
function bm
    bash -lc "bookmark $argv"
    return 0
end
