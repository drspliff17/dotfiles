function wallpaper
    grep 'wallpaper =' ~/.config/waypaper/config.ini | cut -d ' ' -f 3 | string sub -s 3
end
