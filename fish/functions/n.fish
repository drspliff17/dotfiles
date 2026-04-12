function n
    set sock /tmp/nvim-(date +%s%N)-$fish_pid.sock
    command nvim --listen $sock $argv
end
