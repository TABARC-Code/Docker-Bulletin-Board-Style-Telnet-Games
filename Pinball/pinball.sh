#!/usr/bin/env bash
# Pinball: terminal table, fixed-step physics and a modest amount of optimism.
# The game logic can be sourced by the regression checks without touching a TTY.

: "${SCORE_FILE:=/tmp/.pinball_scores}"
: "${PINBALL_TEST_MODE:=0}"

width=40
height=25
scale=100
tick_us=80000             # 12.5 physics steps per second, regardless of input rate.
max_catchup=4             # Catch up a little, then drop lag rather than spiral.
flipper_ttl_max=3

# A single place to reset the state, including the bits the tests need.
reset_game_state() {
    score=0 balls_left=3 ball_in_play=0 game_over=0 quit_requested=0 combo=1
    ball_x=20 ball_y=20 ball_x_fp=2000 ball_y_fp=2000
    ball_vx=0 ball_vy=0
    left_flipper_ttl=0 right_flipper_ttl=0
    bumper_cooldown=0 last_bumper=-1
    ticks_processed=0 next_tick_us=0
    previous_ball_x=-1 previous_ball_y=-1
    bumpers=("10 8 100" "20 6 100" "30 8 100" "15 12 50" "25 12 50")
    targets=("5 10 0" "35 10 0" "8 15 0" "32 15 0")
    bumper_flash=(0 0 0 0 0)
}
reset_game_state

abs() { abs_result=$(( $1 < 0 ? -$1 : $1 )); }

clamp_velocities() {
    ((ball_vx > 350)) && ball_vx=350
    ((ball_vx < -350)) && ball_vx=-350
    ((ball_vy > 400)) && ball_vy=400
    ((ball_vy < -350)) && ball_vy=-350
    return 0
}

launch_ball() {
    if (( !ball_in_play && balls_left > 0 && !game_over )); then
        # The old (-2,-3) shot dropped out before reaching the table.
        # Keep the chute position but give it a slower, longer upward arc.
        ball_x=38 ball_y=22
        ball_x_fp=$((ball_x * scale)) ball_y_fp=$((ball_y * scale))
        ball_vx=-100 ball_vy=-260
        ball_in_play=1 combo=1 bumper_cooldown=0 last_bumper=-1
    fi
}

lose_ball() {
    ball_in_play=0
    ((balls_left--))
    combo=1 ball_vx=0 ball_vy=0
    ((balls_left <= 0)) && game_over=1
    return 0
}

check_bumpers() {
    local i bx by pts dx dy
    for i in "${!bumpers[@]}"; do
        read -r bx by pts <<< "${bumpers[$i]}"
        dx=$((ball_x - bx)) dy=$((ball_y - by))
        if ((dx >= -1 && dx <= 1 && dy >= -1 && dy <= 1)); then
            if ((last_bumper == i && bumper_cooldown > 0)); then
                return 1
            fi
            ((score += pts * combo))
            ((combo < 5)) && ((combo++))
            # Push the ball away from the bumper. No random number generator
            # here: a repeatable bounce is much easier to debug.
            if ((dx < 0)); then ball_vx=-160
            elif ((dx > 0)); then ball_vx=160
            elif ((ball_vx >= 0)); then ball_vx=160
            else ball_vx=-160
            fi
            ball_vy=-240
            bumper_flash[$i]=3
            bumper_cooldown=3 last_bumper=$i
            return 0
        fi
    done
    return 1
}

check_targets() {
    local i tx ty hit j rx ry rhit all_hit
    for i in "${!targets[@]}"; do
        read -r tx ty hit <<< "${targets[$i]}"
        if ((ball_x == tx && ball_y == ty && hit == 0)); then
            targets[$i]="$tx $ty 1"
            ((score += 250 * combo))
            ((combo < 5)) && ((combo++))
            ball_vx=$((-ball_vx))
            # A struck target redirects the shot without adding another drain.
            ((ball_vy > -180)) && ball_vy=-180
            all_hit=1
            for j in "${!targets[@]}"; do
                read -r rx ry rhit <<< "${targets[$j]}"
                ((rhit == 0)) && all_hit=0
            done
            if ((all_hit)); then
                ((score += 1000))
                targets=("5 10 0" "35 10 0" "8 15 0" "32 15 0")
            fi
            return 0
        fi
    done
    return 1
}

check_flippers() {
    ((ball_y >= height - 3 && ball_vy > 0)) || return 1
    if ((ball_x >= width/4 - 2 && ball_x <= width/4 + 2 && left_flipper_ttl > 0)); then
        ball_vy=-330 ball_vx=130
    elif ((ball_x >= width*3/4 - 3 && ball_x <= width*3/4 + 2 && right_flipper_ttl > 0)); then
        ball_vy=-330 ball_vx=-130
    else
        return 1
    fi
    ((score += 10))
    return 0
}

physics_tick() {
    local start_x start_y steps step max_delta
    ((ball_in_play)) || { tick_effects; return 0; }

    # All movement is in hundredths of a cell. Substeps inspect every crossed
    # grid row/column, so a fast shot cannot leap clean over a bumper or flipper.
    ball_vy=$((ball_vy + 12))
    clamp_velocities
    start_x=$ball_x_fp start_y=$ball_y_fp
    abs "$ball_vx"; max_delta=$abs_result
    abs "$ball_vy"; ((abs_result > max_delta)) && max_delta=$abs_result
    steps=$(((max_delta + scale - 1) / scale))
    ((steps < 1)) && steps=1

    for ((step=1; step<=steps; step++)); do
        ball_x_fp=$((start_x + ball_vx * step / steps))
        ball_y_fp=$((start_y + ball_vy * step / steps))
        ball_x=$(((ball_x_fp + scale/2) / scale))
        ball_y=$(((ball_y_fp + scale/2) / scale))

        if ((ball_x <= 0)); then
            ball_x=1 ball_x_fp=$scale ball_vx=$((-ball_vx))
            break
        elif ((ball_x >= width - 1)); then
            ball_x=$((width - 2)) ball_x_fp=$((ball_x * scale))
            ball_vx=$((-ball_vx))
            break
        fi
        if ((ball_y <= 0)); then
            ball_y=1 ball_y_fp=$scale ball_vy=$((-ball_vy))
            break
        fi
        # Test objects and flippers before the drain at the bottom edge.
        if check_bumpers || check_targets || check_flippers; then
            break
        fi
        if ((ball_y >= height - 1)); then
            lose_ball
            break
        fi
    done
    tick_effects
    return 0
}

tick_effects() {
    local i
    ((left_flipper_ttl > 0)) && ((left_flipper_ttl--))
    ((right_flipper_ttl > 0)) && ((right_flipper_ttl--))
    ((bumper_cooldown > 0)) && ((bumper_cooldown--))
    for i in "${!bumper_flash[@]}"; do
        ((bumper_flash[i] > 0)) && ((bumper_flash[i]--))
    done
    return 0
}

process_input() {
    case "$1" in
        a|A) left_flipper_ttl=$flipper_ttl_max ;;
        d|D) right_flipper_ttl=$flipper_ttl_max ;;
        ' ') launch_ball ;;
        q|Q) quit_requested=1 game_over=1 ;;
    esac
    # No physics here. Pressing keys must not make the ball run faster.
    return 0
}

# Accepts an integer microsecond clock value. Kept separate for deterministic tests.
advance_due_ticks() {
    local now=$1 count=0
    while ((now >= next_tick_us && count < max_catchup && !game_over)); do
        physics_tick
        ticks_processed=$((ticks_processed + 1))
        next_tick_us=$((next_tick_us + tick_us))
        count=$((count + 1))
    done
    if ((count == max_catchup && now >= next_tick_us)); then
        next_tick_us=$((now + tick_us))
    fi
    return 0
}

init_scores() {
    [[ -f "$SCORE_FILE" ]] && return 0
    printf 'Anonymous 5000\nGuest 3000\nPlayer 1500\n' > "$SCORE_FILE"
}

save_high_score() {
    local name=${1//[^[:alnum:]_-]/_} points=$2 temp
    name=${name:0:8}
    temp=$(mktemp "${SCORE_FILE}.XXXXXX") || return 1
    { cat "$SCORE_FILE"; printf '%s %d\n' "${name:-Player}" "$points"; } |
        sort -k2,2nr | head -n 10 > "$temp"
    mv -f "$temp" "$SCORE_FILE"
}

show_high_scores() {
    local rank=1 name points
    clear
    printf '╔════════════════════════════════════════╗\n'
    printf '║            PINBALL HIGH SCORES         ║\n'
    printf '╠════════════════════════════════════════╣\n'
    while read -r name points; do
        printf '║ %2d. %-20s %10s ║\n' "$rank" "$name" "$points"
        ((rank++))
    done < "$SCORE_FILE"
    printf '╚════════════════════════════════════════╝\n\nPress any key to continue...'
    local key
    IFS= read -rsn1 key
}

# Rendering is deliberately separate from physics, so tests need no terminal.
draw_board() {
    local line blank i bx by pts tx ty hit
    printf -v line '%*s' "$width" ''
    line=${line// /═}
    printf -v blank '%*s' "$width" ''
    clear
    printf '╔%s╗\n' "$line"
    for ((i=0;i<height;i++)); do printf '║%s║\n' "$blank"; done
    printf '╚%s╝\n' "$line"
    tput cup $((height+2)) 0
    printf 'Score: %-8s | Balls: %-2s | Combo: x%-4s' "$score" "$balls_left" "$combo"
    tput cup $((height+3)) 0
    printf '[A]=Left [D]=Right [SPACE]=Launch [Q]=Quit'
    for ((i=height-5;i<height;i++)); do
        tput cup $((i+1)) "$width"; printf '│'
    done
}

draw_flippers() {
    tput cup "$height" $((width/4))
    if ((left_flipper_ttl)); then printf '╱──'; else printf '───'; fi
    tput cup "$height" $((width*3/4-2))
    if ((right_flipper_ttl)); then printf '──╲'; else printf '───'; fi
}

render_frame() {
    local i bx by pts tx ty hit
    ((PINBALL_TEST_MODE)) && return 0
    if ((previous_ball_x >= 0 && previous_ball_y >= 0)); then
        tput cup $((previous_ball_y+1)) $((previous_ball_x+1)); printf ' '
    fi
    for i in "${!bumpers[@]}"; do
        read -r bx by pts <<< "${bumpers[$i]}"
        tput cup $((by+1)) $((bx+1))
        if ((bumper_flash[i])); then printf '◎'; else printf '◉'; fi
    done
    for i in "${!targets[@]}"; do
        read -r tx ty hit <<< "${targets[$i]}"
        tput cup $((ty+1)) $((tx+1))
        if ((hit)); then printf '░'; else printf '▓'; fi
    done
    draw_flippers
    if ((ball_in_play)); then
        tput cup $((ball_y+1)) $((ball_x+1)); printf '●'
        previous_ball_x=$ball_x previous_ball_y=$ball_y
    else
        previous_ball_x=-1 previous_ball_y=-1
    fi
    tput cup $((height+2)) 0
    printf 'Score: %-8s | Balls: %-2s | Combo: x%-4s' "$score" "$balls_left" "$combo"
}

saved_stty=''
cleanup_terminal() {
    tput cnorm 2>/dev/null || true
    tput rmcup 2>/dev/null || true
    if [[ -n $saved_stty ]]; then stty "$saved_stty" 2>/dev/null || true; fi
}

clock_microseconds() {
    local value=$EPOCHREALTIME
    now_us=${value/./}
}

finish_game() {
    local lowest_score player_name
    ((quit_requested)) && return 0
    tput cup $((height/2)) $((width/2-5)); printf 'GAME OVER'
    tput cup $((height/2+1)) $((width/2-10)); printf 'Final Score: %s' "$score"
    lowest_score=$(tail -n 1 "$SCORE_FILE" 2>/dev/null | awk '{print $2}')
    lowest_score=${lowest_score:-0}
    if ((score > lowest_score || $(wc -l < "$SCORE_FILE") < 10)); then
        tput cup $((height/2+3)) $((width/2-12)); printf 'NEW HIGH SCORE!'
        tput cup $((height/2+4)) $((width/2-12)); printf 'Enter name (8 chars): '
        stty echo icanon
        IFS= read -r -n8 player_name || true
        stty -echo -icanon min 1 time 0
        save_high_score "${player_name:-Player}" "$score"
    fi
    sleep 2
    show_high_scores
}

pinball_main() {
    local key wait_us wait_sec
    if [[ ! -t 0 || ! -t 1 ]]; then
        printf 'Pinball needs an interactive terminal.\n' >&2
        return 1
    fi
    saved_stty=$(stty -g) || return 1
    trap cleanup_terminal EXIT
    trap 'exit 130' INT
    trap 'exit 143' TERM
    stty -echo -icanon min 1 time 0
    tput smcup 2>/dev/null || true
    tput civis 2>/dev/null || true
    init_scores || return 1
    show_high_scores
    draw_board
    render_frame
    clock_microseconds
    next_tick_us=$((now_us + tick_us))
    while ((!game_over)); do
        clock_microseconds
        if ((now_us >= next_tick_us)); then
            advance_due_ticks "$now_us"
            render_frame
        else
            wait_us=$((next_tick_us - now_us))
            ((wait_us > 30000)) && wait_us=30000
            printf -v wait_sec '%d.%06d' $((wait_us/1000000)) $((wait_us%1000000))
            key=''
            IFS= read -rsn1 -t "$wait_sec" key || true
            [[ -n $key ]] && process_input "$key"
        fi
    done
    finish_game
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
    pinball_main "$@"
fi
