#!/usr/bin/env bash
# Deterministic Worm movement, food and input regressions.
set -euo pipefail
cd "$(dirname "$0")/.."
export WORM_TEST_MODE=1
source worm/worm.sh
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
check() { [[ "$1" == "$2" ]] || fail "$3: expected '$2', got '$1'"; }

reset_game_state
check "$worm_len,$score,$dir" '3,0,0' 'initial state'
food_x=0 food_y=0
next_tick_us=120000
advance_due_ticks 119999
check "$ticks_processed,${worm_x[0]}" '0,30' 'premature movement'
advance_due_ticks 120000
check "$ticks_processed,${worm_x[0]}" '1,31' 'first fixed tick'
for ((i=0; i<80; i++)); do process_input z; done
check "$ticks_processed,${worm_x[0]}" '1,31' 'input sped up movement'
advance_due_ticks 240000
check "$ticks_processed,${worm_x[0]}" '2,32' 'second fixed tick'
advance_due_ticks 9999999
check "$ticks_processed" '5' 'bounded catch-up'
check "$next_tick_us" '10119999' 'catch-up resynchronisation'
advance_due_ticks 300000
check "$next_tick_us" '420000' 'backwards clock recovery'
check "$ticks_processed" '5' 'clock reversal moved snake'

reset_game_state
process_input a
check "$pending_dir" '-1' 'reverse input accepted'
process_input $'\e[A'
check "$pending_dir" '3' 'CSI up arrow'
process_input $'\e[D'
check "$pending_dir" '3' 'queued reverse bypassed rule'
process_input $'\eOB'
check "$pending_dir" '1' 'SS3 down arrow'
food_x=0 food_y=0
game_tick
check "$dir,${worm_x[0]},${worm_y[0]}" '1,30,11' 'turn not applied once'
process_input w
check "$pending_dir" '-1' 'down to up reversal accepted'
process_input a
game_tick
check "$dir,${worm_x[0]},${worm_y[0]}" '2,29,11' 'left turn after down'
process_input q
check "$quit_requested,$game_over" '1,1' 'clean quit'

reset_game_state
read_input < <(printf '\033[A')
check "$pending_dir" '3' 'split CSI arrow bytes'
read_input < <(printf '\033OD')
check "$pending_dir" '3' 'split reverse SS3 bytes'
read_input < <(printf '\033[')
check "$pending_dir" '3' 'incomplete escape sequence changed direction'
read_input < <(printf q)
check "$quit_requested,$game_over" '1,1' 'input reader quit'
reset_game_state
read_input </dev/null
check "$quit_requested,$game_over" '1,1' 'EOF did not close game'

reset_game_state
width=4 height=4
worm_x=(3 2 1); worm_y=(1 1 1); worm_len=3
food_x=0 food_y=0
game_tick
check "$game_over,$score" '1,0' 'wall collision'

reset_game_state
width=4 height=4
worm_x=(1 1 0 0); worm_y=(1 0 0 1); worm_len=4
dir=3 food_x=3 food_y=3
game_tick
check "$game_over,$score" '1,0' 'self collision'

reset_game_state
width=4 height=4
worm_x=(1 1 0 0); worm_y=(1 0 0 1); worm_len=4
dir=2 food_x=3 food_y=3
game_tick
check "$game_over,${worm_x[0]},${worm_y[0]}" '0,0,1' 'vacating tail is legal'

reset_game_state
width=4 height=4
worm_x=(1 0 0); worm_y=(1 1 0); worm_len=3
dir=0 food_x=2 food_y=1
game_tick
check "$worm_len,$score,${worm_x[0]},${worm_y[0]}" '4,10,2,1' 'food growth and scoring'
check "${worm_x[3]},${worm_y[3]}" '0,0' 'growth lost old tail'
[[ $food_x -ge 0 && $food_y -ge 0 ]] || fail 'no replacement food'
for ((i=0; i<worm_len; i++)); do
    [[ $food_x != "${worm_x[i]}" || $food_y != "${worm_y[i]}" ]] || fail 'food spawned in body or head'
done

reset_game_state
width=2 height=2
worm_x=(0 1 1); worm_y=(0 0 1); worm_len=3
food_x=0 food_y=1
dir=1
game_tick
check "$worm_len,$score,$won,$game_over" '4,10,1,1' 'full-board victory'
check "$food_x,$food_y" '-1,-1' 'full-board food coordinates'
if place_food; then fail 'full board must not accept new food'; fi

reset_game_state
width=2 height=2
worm_x=(0 1 1 0); worm_y=(0 0 1 1); worm_len=4
if place_food; then fail 'full board food placement loop'; fi

if env -u WORM_TEST_MODE bash worm/worm.sh </dev/null >/dev/null 2>&1; then
    fail 'game must reject non-terminal input'
fi

echo 'Worm gameplay checks passed.'
