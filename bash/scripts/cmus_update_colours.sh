#!/usr/bin/env bash

cp "$HOME/.cache/wal/cmus.theme" \
  "$HOME/.config/cmus/pywal.theme"

tmp=$(mktemp)
input="$HOME/.config/cmus/pywal.theme"

awk '
function hex2dec(h) {
return strtonum("0x" h)
}

function clamp(v, min, max) {
return (v < min ? min : (v > max ? max : v))
}

function rgb_to_ansi(r,g,b,   rc,gc,bc,cube,gray,gray_i,cr,cg,cb,gr,d_cube,d_gray) {
# --- color cube ---
rc = int((r / 255) * 5 + 0.5)
gc = int((g / 255) * 5 + 0.5)
bc = int((b / 255) * 5 + 0.5)

cube = 16 + (36 * rc) + (6 * gc) + bc

# cube back to RGB
cr = rc == 0 ? 0 : 55 + rc * 40
cg = gc == 0 ? 0 : 55 + gc * 40
cb = bc == 0 ? 0 : 55 + bc * 40

d_cube = (r-cr)^2 + (g-cg)^2 + (b-cb)^2

# --- grayscale ---
gray = (r + g + b) / 3
gray_i = 232 + int(((gray - 8) / 247) * 24 + 0.5)
gray_i = clamp(gray_i, 232, 255)

gr = 8 + (gray_i - 232) * 10
d_gray = (r-gr)^2 + (g-gr)^2 + (b-gr)^2

return (d_gray < d_cube ? gray_i : cube)
}

{
line = $0

while (match(line, /#[0-9a-fA-F]{6}/)) {
hex = substr(line, RSTART+1, 6)

r = hex2dec(substr(hex,1,2))
g = hex2dec(substr(hex,3,2))
b = hex2dec(substr(hex,5,2))

ansi = rgb_to_ansi(r,g,b)

line = substr(line,1,RSTART-1) ansi substr(line,RSTART+7)
}

print line
}
' "$input" >"$tmp"

mv "$tmp" "$input"

python3 - "$input" <<'PY'
import sys
import re
import json
from pathlib import Path

theme_path = Path(sys.argv[1])

wal = json.loads(
    (Path.home() / ".cache/wal/colors.json").read_text()
)

wal_bg = tuple(
    bytes.fromhex(wal["special"]["background"].lstrip("#"))
)

MIN_CONTRAST = 7.0

palette = {}

steps = [0, 95, 135, 175, 215, 255]

for i in range(16, 232):
    n = i - 16

    palette[i] = (
        steps[n // 36],
        steps[(n // 6) % 6],
        steps[n % 6],
    )

for i in range(232, 256):
    gray = 8 + (i - 232) * 10
    palette[i] = (gray, gray, gray)

def luminance(rgb):
    def linear(c):
        c /= 255
        return (
            c / 12.92
            if c <= 0.04045
            else ((c + 0.055) / 1.055) ** 2.4
        )
    r, g, b = map(linear, rgb)

    return (
        0.2126 * r +
        0.7152 * g +
        0.0722 * b
    )


def contrast(a, b):
    x = luminance(a)
    y = luminance(b)
    return (max(x, y) + 0.05) / (min(x, y) + 0.05)


def rgb(value):
    if value == "default":
        return wal_bg
    return palette[int(value)]


def distance(a, b):
    return sum((x - y) ** 2 for x, y in zip(a, b))

neutrals = [16, 231] + list(range(232, 256))
theme = theme_path.read_text()
settings = dict(
    re.findall(
        r"(?m)^set (color_\w+)=(\S+)",
        theme
    )
)

pairs = {
    "color_win_fg": "color_win_bg",
    "color_win_cur": "color_win_bg",
    "color_win_dir": "color_win_bg",

    "color_win_title_fg": "color_win_title_bg",

    "color_cmdline_fg": "color_cmdline_bg",
    "color_error": "color_cmdline_bg",
    "color_info": "color_cmdline_bg",

    "color_statusline_fg": "color_statusline_bg",
    "color_titleline_fg": "color_titleline_bg",

    "color_win_sel_fg": "color_win_sel_bg",

    "color_win_cur_sel_fg": "color_win_cur_sel_bg",

    "color_win_inactive_sel_fg":
        "color_win_inactive_sel_bg",

    "color_win_inactive_cur_sel_fg":
        "color_win_inactive_cur_sel_bg",
}

for fg, bg in pairs.items():
    if fg not in settings or bg not in settings:
        continue

    original = rgb(settings[fg])
    background = rgb(settings[bg])

    if contrast(original, background) >= MIN_CONTRAST:
        continue

    candidates = [
        n for n in neutrals
        if contrast(palette[n], background) >= MIN_CONTRAST
    ]

    if candidates:
        best = min(
            candidates,
            key=lambda n: distance(palette[n], original)
        )

    else:
        best = max(
            neutrals,
            key=lambda n: contrast(palette[n], background)
        )

    settings[fg] = str(best)

def replace(match):
    name = match.group(2)
    return (
        match.group(1) +
        settings.get(name, match.group(3))
    )

theme = re.sub(
    r"(?m)^(set (color_\w+)=)(\S+)",
    replace,
    theme
)
theme_path.write_text(theme)
PY

cmus-remote -C "source $input"
