#!/bin/bash
export PATH="$HOME/.local/bin:$PATH"
cd $HOME/projects/python-kasa
ENV_FILE="$(dirname "$(readlink -f "$0")")/iot_scan.env"
[ -z "$IOT_SUBNET" ] && [ -f "$ENV_FILE" ] && . "$ENV_FILE"
SUBNET="${IOT_SUBNET:?set IOT_SUBNET in iot_scan.env (see iot_scan.env.example)}"
# IPs that answered a Kasa query last run; re-checked with retries if this run misses them,
# so a device that stalls for a few seconds isn't reported as MISSING/OFFLINE.
CACHE="$HOME/.cache/iot_scan/known_ips"
RETRIES=3
RETRY_DELAY=10

# query IP ATTEMPTS: print Kasa state JSON, retrying on failure
query() {
  local out i
  for ((i = 1; i <= $2; i++)); do
    out=$(uv run kasa --host "$1" --json state 2>/dev/null)
    [[ $? -eq 0 && $out == \{* ]] && { echo "$out"; return 0; }
    [ "$i" -lt "$2" ] && sleep "$RETRY_DELAY"
  done
  return 1
}

declare -A KNOWN FOUND
[ -f "$CACHE" ] && while IFS= read -r IP; do [ -n "$IP" ] && KNOWN[$IP]=1; done < "$CACHE"

OUT='['
SEP=''
ANSWERED=()
add() { OUT="${OUT}${SEP}{\"ip\":\"$1\",\"kasa\":$2}"; SEP=','; }

while IFS= read -r IP; do
  [ -z "$IP" ] && continue
  FOUND[$IP]=1
  # Unknown hosts get one attempt, so non-Kasa hosts don't slow every run
  N=1; [ -n "${KNOWN[$IP]}" ] && N=$RETRIES
  if K=$(query "$IP" "$N"); then ANSWERED+=("$IP"); else K='{}'; fi
  add "$IP" "$K"
done < <(nmap -n -Pn -p 9999,20002,80 --host-timeout 10s -T4 -oG - "$SUBNET" 2>/dev/null | grep '/open/' | awk '{print $2}' | sort -u)

# Known devices the port scan missed: query them directly before declaring them gone
for IP in "${!KNOWN[@]}"; do
  [ -n "${FOUND[$IP]}" ] && continue
  if K=$(query "$IP" "$RETRIES"); then ANSWERED+=("$IP"); add "$IP" "$K"; fi
done

mkdir -p "$(dirname "$CACHE")"
printf '%s\n' "${ANSWERED[@]}" > "$CACHE.tmp" && mv "$CACHE.tmp" "$CACHE"
echo "${OUT}]"
