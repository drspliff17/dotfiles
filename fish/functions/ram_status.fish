#!/usr/bin/env fish

function ram_status
    set total (awk '/MemTotal/ {print $2}' /proc/meminfo)
    set available (awk '/MemAvailable/ {print $2}' /proc/meminfo)

    if test $available -ge 1048576
        set available_hr (math "$available / 1024 / 1024" | xargs printf "%.1f GB")
    else
        set available_hr (math "$available / 1024" | xargs printf "%.0f MB")
    end

    set used_percent (math "100 * ($total - $available) / $total")
    set formatted (printf "%02d" $used_percent)

    echo "{\"text\":\"   $formatted% ($available_hr)\",\"alt\":\"\"}"
end
