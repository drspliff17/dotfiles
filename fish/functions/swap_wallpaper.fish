#!/usr/bin/env fish

function swap_wallpaper
    /usr/bin/waypaper --random >/dev/null
    set wallpaper (cat ~/.config/waypaper/config.ini | grep "wallpaper =" | cut -d ' ' -f 3 | string sub -s 3 --)
    /usr/bin/wal -i "$HOME/$wallpaper" >/dev/null 2>&1

    if test -f "$HOME/.cache/wal/hyprlock.conf"
        cp "$HOME/.cache/wal/hyprlock.conf" "$HOME/.config/hypr/hyprlock.conf"
    end

    # Kitty Sockets (specifically needed for tab bar pywal update)
    for paw in /tmp/kitty-*
        test -S $paw; or continue
        kitty @ --to "unix:$paw" set-colors --all --configured ~/.cache/wal/colors-kitty.conf
    end

    # Neovim
    for sock in /tmp/nvim-*
        if test -S $sock
            nvim --server $sock --remote-expr "execute ('colorscheme pywal')"
        end
    end

    # Waypaper
    cp ~/.cache/wal/waypaper.css ~/.config/waypaper/style.css

    # Dunst
    cp ~/.cache/wal/dunstrc ~/.config/dunst/dunstrc
    dunstctl reload

    # Firefox
    pywalfox update

    # Discord
    pywal-discord -t mywal

    # Cmus
    cp ~/.cache/wal/cmus.theme ~/.config/cmus/pywal.theme
    set tmp (mktemp)
    set input "/home/drspliff/.config/cmus/pywal.theme"
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
    cmus-remote -C "source $input"

    #BTOP
    # cp ~/.cache/wal/btop.theme ~/.config/btop/themes/pywal.theme

end
