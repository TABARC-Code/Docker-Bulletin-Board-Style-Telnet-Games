#!/usr/bin/env bash
# No Docker daemon needed: check the exact publish flags and Compose templates.
set -euo pipefail
cd "$(dirname "$0")/.."

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
default_runs="$(make -n run-all)"
lan_runs="$(make -n run-all BIND_ADDR=192.0.2.55)"

for entry in "worm:2323" "Robot:2324" "Pinball:2325" "Hunt the Wumpus:2326"; do
    folder=${entry%:*}
    port=${entry##*:}
    grep -Fq -- "-p 127.0.0.1:$port:2323" <<< "$default_runs" || fail "make exposes $port by default"
    grep -Fq -- "-p 192.0.2.55:$port:2323" <<< "$lan_runs" || fail "make cannot bind LAN interface $port"
    grep -Fq -- '"${BIND_ADDR:-127.0.0.1}:'"$port"':2323"' "$folder/docker-compose.yml" || fail "Compose binding incorrect for $folder"
done

echo "Telnet network binding checks passed."
