#!/usr/bin/env bash
# Regression checks for movement state and robot collision handling.
set -euo pipefail
cd "$(dirname "$0")/.."
game="Robot/Robots.sh"

bash -n "$game"
if sed -n '/^# Main/,$p' "$game" | grep -Eq '^[[:space:]]+local([[:space:]]|$)'; then
    echo "FAIL: local used outside a function in the game loop" >&2
    exit 1
fi

# Load the actual function without starting an interactive game.
source <(sed -n '/^move_robots() {/,/^}/p' "$game")
draw_at() { :; }
sleep() { :; }
init_level() { echo "Unexpected level reset" >&2; exit 1; }

check() {
    if [[ "$1" != "$2" ]]; then
        echo "FAIL: $3: expected '$2', got '$1'" >&2
        exit 1
    fi
}

reset_case() {
    width=20; height=20; level=1; score=0; game_over=0
    player_x=2; player_y=2
    robot_x=(); robot_y=(); junk_x=(); junk_y=()
}

# Two robots collide at (2,2). Both must die and make one scrap heap.
reset_case
robot_x=(1 3 10); robot_y=(1 3 10)
move_robots
check "${#robot_x[@]}" 1 "two-robot collision survivors"
check "${robot_x[0]},${robot_y[0]}" "9,9" "remaining robot"
check "${#junk_x[@]}" 1 "single scrap heap"
check "${junk_x[0]},${junk_y[0]}" "2,2" "scrap position"
check "$score" 20 "two-robot collision score"
check "$game_over" 0 "collision at player does not kill player"

# Three robots reaching the same square must all be destroyed.
reset_case
robot_x=(1 3 2 10); robot_y=(1 3 1 10)
move_robots
check "${#robot_x[@]}" 1 "three-robot collision survivors"
check "${#junk_x[@]}" 1 "three-robot debris count"
check "$score" 30 "three-robot collision score"

# Distinct destinations must keep both robots alive.
reset_case
player_x=5; player_y=5
robot_x=(1 9); robot_y=(1 9)
move_robots
check "${#robot_x[@]}" 2 "independent robots"
check "${#junk_x[@]}" 0 "no phantom debris"
check "$score" 0 "no phantom score"

# A robot hitting existing scrap is removed without adding a duplicate.
reset_case
player_x=3; player_y=3
junk_x=(2); junk_y=(2)
robot_x=(1 10); robot_y=(1 10)
move_robots
check "${#robot_x[@]}" 1 "robot hits existing debris"
check "${#junk_x[@]}" 1 "debris is not duplicated"

# One robot reaching the player still ends the game.
reset_case
robot_x=(1 10); robot_y=(1 10)
move_robots
check "$game_over" 1 "direct player collision"
echo "Robots regression checks passed."
