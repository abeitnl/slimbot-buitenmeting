#!/usr/bin/env bash
# SLIMBOT-BUITENMETING-MEETPUNT-20261109
# Meet Slimbot van buitenaf: elke minuut drie adressen, met responstijd.
# Schrijft één JSON-regel per meting naar data/JJJJ-MM-DD.jsonl (UTC-dag).
# Alleen lezen: de livechat-API wordt alleen om de instellingen van een voorbeeldwidget gevraagd.
set -u
RONDES="${RONDES:-5}"
TUSSEN="${TUSSEN:-60}"
LIVECHAT_URL="${LIVECHAT_URL:-}"
RUN="${GITHUB_RUN_ID:-lokaal}"
UA='SlimbotBuitenmeting/1 (+https://slimbot.nl/status)'
mkdir -p data

meet() {
  local doel="$1" url="$2" anker="$3"
  local body err uit rc code tijd ok reden t
  body="$(mktemp)"; err="$(mktemp)"
  t="$(date -u +%s)"
  uit="$(curl -sS -o "$body" -w '%{http_code} %{time_total}' --max-time 20 --connect-timeout 10 -A "$UA" -H 'Cache-Control: no-cache' "$url" 2>"$err")"
  rc=$?
  code="${uit%% *}"; tijd="${uit##* }"
  [[ "$code" =~ ^[0-9]+$ ]] && code=$((10#$code)) || code=0
  [[ "$tijd" =~ ^[0-9.]+$ ]] || tijd=0
  ok=0; reden=""
  if [ "$rc" -ne 0 ]; then
    reden="curl $rc $(head -c 120 "$err" | tr -d '"\\\n\r')"
  elif [ "$code" != "200" ]; then
    reden="http $code"
  elif ! grep -qF -- "$anker" "$body"; then
    reden="anker ontbreekt"
  else
    ok=1
  fi
  printf '{"t":%s,"doel":"%s","ok":%d,"http":%s,"ms":%d,"reden":"%s","run":"%s"}\n' \
    "$t" "$doel" "$ok" "$code" "$(awk -v s="$tijd" 'BEGIN{printf "%d", s*1000}')" "$reden" "$RUN" \
    >> "data/$(date -u -d "@$t" +%F).jsonl"
  rm -f "$body" "$err"
}

for i in $(seq 1 "$RONDES"); do
  begin="$(date +%s)"
  meet login    'https://slimbot.nl/login'  'name="password"'
  if [ -n "$LIVECHAT_URL" ]; then
    meet livechat "$LIVECHAT_URL"          '"ok":true'
  fi
  meet status   'https://slimbot.nl/status' 'Status van Slimbot'
  if [ "$i" -lt "$RONDES" ]; then
    rest=$(( begin + TUSSEN - $(date +%s) ))
    [ "$rest" -gt 0 ] && sleep "$rest"
  fi
done
exit 0
