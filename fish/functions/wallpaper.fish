function wallpaper
    awww query -j | jq '.[].[] | .displaying.image' | sort -u
end
