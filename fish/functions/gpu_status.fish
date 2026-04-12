#!/usr/bin/env fish

function gpu_status
    set temp (nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits)
    set usage (nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits)
    set usage_fmt (printf "%02d" $usage)

    echo "{\"text\":\"󰊗  $usage_fmt% ($temp°C)\",\"alt\": \"\"}"
end
