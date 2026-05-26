mkdir -p ~/Pictures/archimg
cd ~/Pictures/archimg

seq -w 001 999 | xargs -P 16 -I{} bash -c '
url="https://archimg.cc/assets/{}.jpg"
out="{}.jpg"

if curl -sf "$url" -o "$out"; then
    echo "downloaded $out"
fi
'
