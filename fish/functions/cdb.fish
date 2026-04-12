#!/usr/bin/env fish
function cdb
    set result (bash -lc "cdb $argv")
    if test $status -eq 0
        cd $result
    end
    return 0
end
