#!/usr/bin/env fish

function gpu_status
    set temp (nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits)
    set usage (nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits)
    set usage_fmt (printf "%02d" $usage)

    echo "$usage_fmt% ($temp)" | jq -R -c '{text: .}'
end
