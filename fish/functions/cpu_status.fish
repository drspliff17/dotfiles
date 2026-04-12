#!/usr/bin/env fish

function cpu_status
    set usage (top -bn1 | grep "Cpu(s)" | awk '{print int($2 + $4)}')
    set usage_fmt (printf "%02d" $usage)

    set mem (free | awk '/Mem:/ {print int($3/$2 * 100)}')
    set mem_fmt (printf "%02d" $mem)

    set temp (sensors | awk '
        /Tctl:/ {gsub(/[+°C]/,"",$2); print int($2); exit}
        /Tdie:/ {gsub(/[+°C]/,"",$2); print int($2); exit}
    ')

    echo "{\"text\":\"  $usage_fmt% ($temp°C)\",\"alt\":\"\"}"
end
