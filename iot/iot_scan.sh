#!/bin/bash
export PATH="$HOME/.local/bin:$PATH"
cd $HOME/projects/python-kasa
OUT='['
SEP=''
while IFS= read -r IP; do
  [ -z "$IP" ] && continue
  K=$(uv run kasa --host "$IP" --json state 2>/dev/null || echo '{}')
  OUT="${OUT}${SEP}{\"ip\":\"${IP}\",\"kasa\":${K}}"
  SEP=','
done < <(nmap -n -Pn -p 9999,20002,80 --host-timeout 10s -T4 -oG - 10.50.55.0/24 2>/dev/null | grep '/open/' | awk '{print $2}' | sort -u)
echo "${OUT}]"
