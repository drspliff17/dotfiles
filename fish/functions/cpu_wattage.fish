#!/usr/bin/env fish

function cpu_wattage
    bash -lc "bash_cpu_wattage $argv"
    return 0
end
