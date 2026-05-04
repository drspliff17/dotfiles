#!/usr/bin/env fish

set temp (nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null | string trim)
set usage (nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null | string trim)

test -n "$temp"; or set temp "?"
test -n "$usage"; or set usage "?"

printf '{"text":"%s%% (%sC)"}\n' $usage $temp
