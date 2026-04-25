#!/usr/bin/env bash

tString=""
hString=""
case "$1" in
resize)
  tString="Resize Mode (Active)"
  hString=$(
    cat <<EOF
[Resize Controls]
(-10,0)  ^h   (0,10)  ^j
(0,-10)  ^k   (10,0)  ^l

(-60,0)  h    (0,60)  j
(0,-60)  k    (60,0)  l

[Swap Mode]
(Move )  m
(Reset)  Space
EOF
  )
  ;;

movefloat)
  tString="Move Mode (Floating)"
  hString=$(
    cat <<EOF
[Move Controls]
(-5,0)  ^h   (0,5)  ^j
(0,-5)  ^k   (5,0)  ^l

(-25,0)  h    (0,25)  j
(0,-25)  k    (25,0)  l

(Center)  c

[Swap Mode]
(Resize)  r
(Reset )  Space

EOF
  )
  ;;

open)
  tString="Open Mode"
  hstring=$(
    cat <<EOF
[Open Controls]
(Hyprlauncher)  Space
(Dolphin)       E
(Discord)       D
(Firefox)       B
(Waypaper)      W
(Steam)         S
EOF
  )
  ;;

*)
  exit 1
  ;;
esac

[[ -z "$tString" || -z "$hString" ]] && exit 1
notify-send -u normal -t 5000 -e "$tString" "$hString"
