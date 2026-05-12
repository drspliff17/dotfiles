#!/usr/bin/env bash

BINDINGS_FILE="$HOME/.config/hypr/modules/hyprland_keybindings.lua"
awk '
BEGIN {
    submap = "global"
    first = 1

    print "["
}

# collect local vars
/^[[:space:]]*local[[:space:]]+[a-zA-Z0-9_]+[[:space:]]*=/ {
    if (match($0, /local[[:space:]]+([a-zA-Z0-9_]+)[[:space:]]*=[[:space:]]*"([^"]+)"/, m)) {
        vars[m[1]] = m[2]
    }
}

# submap start
/hl\.define_submap\(/ {
    if (match($0, /"[^"]+"/)) {
        submap = substr($0, RSTART + 1, RLENGTH - 2)
    }
}

# submap end
/^[[:space:]]*end\)/ {
    submap = "global"
}

# bind parser
/hl\.bind\(/ {

    block = $0

    while (block !~ /\)/ && getline) {
        block = block "\n" $0
    }

    bind = ""
    cmd = ""

    # key extraction
    if (match(block, /hl\.bind\([^,]+,/, m)) {

        bind = m[0]

        gsub(/^hl\.bind\(/, "", bind)
        gsub(/,$/, "", bind)

        # convert Lua concatenation
        gsub(/\.\./, " ", bind)

        # remove quotes
        gsub(/"/, "", bind)

        # normalise plus spacing
        gsub(/[[:space:]]*\+[[:space:]]*/, " + ", bind)

        # remove leading "+"
        gsub(/^[[:space:]]*\+[[:space:]]*/, "", bind)

        # collapse whitespace
        gsub(/[[:space:]]+/, " ", bind)

        # trim
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", bind)
    }

    # exec_cmd
    if (match(block, /exec_cmd\([^)]*\)/)) {

        cmd = substr(block, RSTART, RLENGTH)
        gsub(/^exec_cmd\(/, "", cmd)
        gsub(/\)$/, "", cmd)

        for (v in vars) gsub(v, vars[v], cmd)

        gsub(/\.\./, "", cmd)
        gsub(/"/, "", cmd)
        gsub(/[[:space:]]+/, " ", cmd)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", cmd)
    }

    # exec_raw
    else if (match(block, /exec_raw\([^)]*\)/)) {

        cmd = substr(block, RSTART, RLENGTH)
        gsub(/^exec_raw\(/, "", cmd)
        gsub(/\)$/, "", cmd)

        for (v in vars) gsub(v, vars[v], cmd)

        gsub(/\.\./, "", cmd)
        gsub(/"/, "", cmd)
        gsub(/[[:space:]]+/, " ", cmd)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", cmd)
    }

    # hl.dsp.*
    else if (match(block, /hl\.dsp\.[a-zA-Z0-9_\.]+\([^)]*\)/)) {

        cmd = substr(block, RSTART, RLENGTH)

        for (v in vars) gsub(v, vars[v], cmd)

        gsub(/\.\./, "", cmd)
        gsub(/"/, "", cmd)
        gsub(/[[:space:]]+/, " ", cmd)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", cmd)
    }

    # fallback
    else {
        cmd = "[unknown]"
    }

    # JSON escaping
    gsub(/\\/, "\\\\", bind)
    gsub(/"/, "\\\"", bind)

    gsub(/\\/, "\\\\", cmd)
    gsub(/"/, "\\\"", cmd)

    gsub(/\\/, "\\\\", submap)
    gsub(/"/, "\\\"", submap)

    # output JSON array
    if (!first) print ","
    first = 0

    printf "  {\n"
    printf "    \"submap\": \"%s\",\n", submap
    printf "    \"bind\": \"%s\",\n", bind
    printf "    \"command\": \"%s\"\n", cmd
    printf "  }"
}

END {
    print "\n]"
}
' "$BINDINGS_FILE" | jq '
group_by(.submap)
| map({
    Name: .[0].submap,
    Items: map({
        Name: .bind,
        Command: .command
    })
})
'
