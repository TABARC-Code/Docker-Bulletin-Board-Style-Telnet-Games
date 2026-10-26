#!/usr/bin/env bash
# Wumpus rules checks. A clue is not meant to be the answer in disguise.
set -euo pipefail
cd "$(dirname "$0")/.."
game="Hunt the Wumpus/wumpus.sh"

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
bash -n "$game"
source <(sed -n '/^init_puzzles() {/,/^}/p' "$game")
source <(sed -n '/^normalise_answer() {/,/^}/p' "$game")
source <(sed -n '/^matches_answer() {/,/^}/p' "$game")
source <(sed -n '/^place_hazards() {/,/^}/p' "$game")

declare -A puzzles=()
declare -A puzzle_answers=()
init_puzzles
[[ ${#puzzles[@]} -eq 4 ]] || fail "missing logic puzzles"

for index in 1 2 3 4; do
    IFS='|' read -r question hint <<< "${puzzles[$index]}"
    [[ -n "$question" && -n "$hint" ]] || fail "incomplete puzzle $index"
    [[ "${question,,}" != *"${puzzle_answers[$index]}"* ]] || fail "question leaks answer $index"
    [[ "${hint,,}" != *"${puzzle_answers[$index]}"* ]] || fail "hint leaks answer $index"
done

matches_answer "  HEAT  " heat || fail "capitalisation and whitespace"
matches_answer "4   2   1" "4 2 1" || fail "number sequence whitespace"
matches_answer "Chicken" chicken || fail "case-insensitive exact match"
if matches_answer "no heat" heat; then fail "substring accepted for heat"; fi
if matches_answer "threefold" three; then fail "substring accepted for three"; fi
if matches_answer "chicken sandwich" chicken; then fail "substring accepted for chicken"; fi
[[ "${puzzle_answers[3]}" == "4 2 1" ]] || fail "ball-weighing puzzle has no real answer"

# The Wumpus, hazards and the player's starting cave must never overlap.
num_caves=35
declare -a pit_caves=() bat_caves=() riddle_caves=() puzzle_caves=()
declare -a solved_riddles=() solved_puzzles=()
for ((trial=0; trial<120; trial++)); do
    player_cave=$((RANDOM % num_caves + 1))
    place_hazards
    declare -A occupied_test=()
    for cave in "$player_cave" "$wumpus_cave" "${pit_caves[@]}" "${bat_caves[@]}" "${riddle_caves[@]}" "${puzzle_caves[@]}"; do
        [[ $cave =~ ^[0-9]+$ ]] || fail "non-numeric cave"
        ((cave >= 1 && cave <= num_caves)) || fail "out of range cave $cave"
        [[ -z ${occupied_test[$cave]+present} ]] || fail "hazard overlap at cave $cave"
        occupied_test[$cave]=1
    done
    [[ ${#occupied_test[@]} -eq 13 ]] || fail "wrong hazard count"
    unset occupied_test
done

grep -Fq 'read -s -n1 action || exit 0' "$game" || fail "disconnected players are not handled"

# Restoring a terminal must not mask an earlier failure code.
set +e
TERM=xterm bash -c '
    source <(sed -n "/^cleanup() {/,/^}/p" "$1")
    trap cleanup EXIT
    exit 17
' _ "$game" >/dev/null 2>&1
status=$?
set -e
[[ $status -eq 17 ]] || fail "exit status lost during cleanup (got $status)"

echo "Wumpus gameplay checks passed."
