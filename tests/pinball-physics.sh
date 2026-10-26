#!/usr/bin/env bash
# Pinball logic checks. No terminal, Docker daemon or lucky timing required.
set -euo pipefail
cd "$(dirname "$0")/.."
export PINBALL_TEST_MODE=1
source Pinball/pinball.sh

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
assert_eq() { [[ $1 == "$2" ]] || fail "$3: expected $2, got $1"; }
assert_true() { (( $1 )) || fail "$2"; }

reset_game_state
launch_ball
assert_eq "$ball_x,$ball_y" '38,22' 'launch chute'
for ((i=0;i<12;i++)); do
    physics_tick
    if ((i < 8)); then assert_eq "$ball_in_play" 1 'launch drained before reaching the table'; fi
done
assert_true "$((score >= 100))" 'standard launch missed every bumper'
assert_eq "$balls_left" 3 'standard launch lost a ball'

# An unattended shot should eventually drain, rather than loop for ever.
for ((i=0;i<70 && ball_in_play;i++)); do physics_tick; done
assert_eq "$ball_in_play" 0 'unattended shot never drained'

reset_game_state
launch_ball
for ((i=1;i<=19;i++)); do physics_tick; done
assert_eq "$ball_in_play" 1 'flipper approach is playable'
process_input d
physics_tick
assert_eq "$ball_in_play" 1 'right flipper did not save the ball'
assert_true "$((ball_vy < 0))" 'right flipper did not send the ball up'
assert_true "$((score >= 110))" 'flipper save was not scored'

reset_game_state
ball_in_play=1 ball_x=7 ball_y=8
ball_x_fp=700 ball_y_fp=800 ball_vx=350 ball_vy=-12
physics_tick
assert_eq "$score" 100 'fast shot skipped bumper'
assert_true "$((ball_vy < 0))" 'bumper failed to redirect fast shot'

reset_game_state
ball_in_play=1 ball_x=7 ball_y=8 ball_x_fp=700 ball_y_fp=800
ball_vx=350 ball_vy=-12 combo=5
physics_tick
assert_eq "$combo" 5 'combo multiplier must be bounded'

reset_game_state
ball_in_play=1 ball_x=2 ball_y=10
ball_x_fp=200 ball_y_fp=1000 ball_vx=350 ball_vy=-12
physics_tick
assert_eq "$score" 250 'fast shot skipped target'
[[ ${targets[0]} == '5 10 1' ]] || fail 'target hit flag not set'

reset_game_state
ball_in_play=1 ball_x=10 ball_y=19
ball_x_fp=1000 ball_y_fp=1900 ball_vx=0 ball_vy=400
process_input a
physics_tick
assert_eq "$score" 10 'fast shot skipped flipper'
assert_true "$((ball_vy < 0))" 'flipper failed to reverse fast descent'

reset_game_state
ball_in_play=1 ball_x=20 ball_y=22
ball_x_fp=2000 ball_y_fp=2200 ball_vx=0 ball_vy=400
physics_tick
assert_eq "$ball_in_play" 0 'missed ball did not drain'
assert_eq "$balls_left" 2 'drain did not consume one ball'

reset_game_state
launch_ball
next_tick_us=80000
advance_due_ticks 160000
assert_eq "$ticks_processed" 2 'initial fixed ticks'
first_x=$ball_x_fp first_y=$ball_y_fp
for ((i=0;i<100;i++)); do process_input z; done
assert_eq "$ticks_processed" 2 'input unexpectedly advanced physics'
assert_eq "$ball_x_fp,$ball_y_fp" "$first_x,$first_y" 'input changed ball position'
advance_due_ticks 240000
assert_eq "$ticks_processed" 3 'next fixed tick'

reset_game_state
launch_ball
next_tick_us=80000
advance_due_ticks 99999999
assert_eq "$ticks_processed" 4 'catch-up limit'
assert_eq "$next_tick_us" 100079999 'catch-up resynchronisation'

reset_game_state
process_input q
assert_eq "$game_over,$quit_requested" '1,1' 'clean quit'
assert_eq "$balls_left" 3 'quit should not drain a ball'

if bash Pinball/pinball.sh </dev/null >/dev/null 2>&1; then
    fail 'game should refuse to run without a terminal'
fi

echo 'Pinball physics and input checks passed.'
