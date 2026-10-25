#!/usr/bin/env bash
# The cave network must be navigable in both directions.
set -euo pipefail
cd "$(dirname "$0")/.."
game="Hunt the Wumpus/wumpus.sh"

bash -n "$game"
declare -A cave_connections=()
source <(sed -n '/^generate_caves() {/,/^}/p' "$game")
source <(sed -n '/^is_adjacent_from() {/,/^}/p' "$game")
generate_caves

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
[[ ${#cave_connections[@]} -eq 35 ]] || fail "expected 35 caves"

four_exit_caves=0
for ((cave=1; cave<=35; cave++)); do
    [[ -n ${cave_connections[$cave]:-} ]] || fail "missing cave $cave"
    IFS=',' read -r -a neighbours <<< "${cave_connections[$cave]}"
    (( ${#neighbours[@]} >= 3 && ${#neighbours[@]} <= 4 )) || fail "bad exit count in cave $cave"
    if (( ${#neighbours[@]} == 4 )); then four_exit_caves=$((four_exit_caves + 1)); fi
    declare -A exits_seen=()
    for neighbour in "${neighbours[@]}"; do
        [[ $neighbour =~ ^[0-9]+$ ]] || fail "invalid cave $neighbour"
        (( neighbour >= 1 && neighbour <= 35 && neighbour != cave )) || fail "invalid exit $cave:$neighbour"
        [[ -z ${exits_seen[$neighbour]+set} ]] || fail "duplicate exit $cave:$neighbour"
        exits_seen[$neighbour]=1
        is_adjacent_from "$neighbour" "$cave" || fail "one-way tunnel $cave:$neighbour"
    done
    unset exits_seen
done
[[ $four_exit_caves -eq 3 ]] || fail "expected three four-exit caves"

# Every cave must be reachable from the first, not merely present in the table.
declare -A visited=([1]=1)
queue=(1)
for ((index=0; index<${#queue[@]}; index++)); do
    cave=${queue[$index]}
    IFS=',' read -r -a neighbours <<< "${cave_connections[$cave]}"
    for neighbour in "${neighbours[@]}"; do
        if [[ -z ${visited[$neighbour]+set} ]]; then
            visited[$neighbour]=1
            queue+=("$neighbour")
        fi
    done
done
[[ ${#visited[@]} -eq 35 ]] || fail "cave map has unreachable rooms"

# Both the arrow and the Wumpus must use the actual exit count.
grep -Fq 'RANDOM % ${#adj[@]}' "$game" || fail "arrow uses fixed exit count"
grep -Fq 'RANDOM % ${#wumpus_adj[@]}' "$game" || fail "Wumpus uses fixed exit count"

# Verify the image build includes the data read beside the installed script.
dockerfile="Hunt the Wumpus/Dockerfile"
asset="Hunt the Wumpus/death_messages.txt"
[[ -s "$asset" ]] || fail "missing death messages"
grep -Fq 'COPY death_messages.txt /usr/local/games/death_messages.txt' "$dockerfile" || fail "Dockerfile does not install messages"
source <(sed -n '/^load_death_messages() {/,/^}/p' "$game")
DEATH_MESSAGES_FILE="$asset"
death_messages=()
load_death_messages
(( ${#death_messages[@]} > 5 )) || fail "only fallback death messages loaded"

echo "Wumpus map and message checks passed."
