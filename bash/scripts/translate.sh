MSG="$1"
[[ -z "$MSG" ]] && exit 1
S_LANG="${2:-en}"
T_LANG="${3:-fr}"
curl -X POST "http://127.0.0.1:5000/translate" \
  -H "Content-Type: application/json" \
  -d "$(jq -n --arg q "$MSG" --arg s "$S_LANG" --arg t "$T_LANG" '{
      q: $q,
      source: $s,
      target: $t
    }')" | jq
exit 0
