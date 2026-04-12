#!/usr/bin/env fish
function pywal_cmus_convert
    set input $argv[1]

    if test -z "$input"
        echo "Usage: pywal_cmus_convert <file>"
        return 1
    end

    if not test -f "$input"
        echo "File not found: $input"
        return 1
    end

    set tmp (mktemp)

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
end
