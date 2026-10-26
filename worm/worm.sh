#!/usr/bin/env bash
# Worm - Classic ASCII Snake Game
# A proper clock for movement. Keyboard enthusiasm is not a difficulty setting.

: "${SCORE_FILE:=/tmp/.worm_scores}"
readonly TICK_US=120000 MAX_CATCHUP=3

reset_game_state() {
    width=60 height=20 score=0 game_over=0 quit_requested=0 won=0
    worm_x=(30 29 28); worm_y=(10 10 10); worm_len=3
    dir=0 pending_dir=-1
    food_x=-1 food_y=-1
    grew=0 moved=0 last_tail_x=-1 last_tail_y=-1
    ticks_processed=0 next_tick_us=0 last_clock_us=0
}

init_scores() {
    [[ -f "$SCORE_FILE" ]] && return 0
    cat > "$SCORE_FILE" <<'SCORES'
Snake 500
Worm 300
Player 150
SCORES
}

save_high_score() {
    local name=$1 pts=$2 temp
    temp=$(mktemp "${SCORE_FILE}.XXXXXX") || return 1
    printf '%s %s\n' "$name" "$pts" >> "$SCORE_FILE"
    LC_ALL=C sort -k2,2nr "$SCORE_FILE" | head -10 > "$temp"
    mv -f -- "$temp" "$SCORE_FILE"
}

show_high_scores() {
    clear
    printf '%s\n' '╔════════════════════════════════════════════════════════════╗' \
        '║                    WORM HIGH SCORES                        ║' \
        '╠════════════════════════════════════════════════════════════╣'
    local rank=1 name pts
    while read -r name pts; do
        printf '║ %2d. %-30s %20s ║\n' "$rank" "$name" "$pts"
        ((rank+=1))
    done < "$SCORE_FILE"
    printf '%s\n\n' '╚════════════════════════════════════════════════════════════╝'
    printf '%s\n' 'Press any key to start...'
    IFS= read -rsn1
}

draw_border() {
    local hline blank
    printf -v blank '%*s' "$width" ''
    hline=${blank// /─}
    clear
    printf '┌%s┐\n' "$hline"
    local y
    for ((y=0; y<height; y++)); do printf '│%s│\n' "$blank"; done
    printf '└%s┘\n' "$hline"
    tput cup $((height + 2)) 0
    printf 'Score: %s | WASD/Arrows to move | Q to quit\n' "$score"
    tput cup 0 $((width + 5))
    printf '[ WORM v1.4 ]'
}

draw_at() {
    tput cup $(($2 + 1)) $(($1 + 1))
    printf '%s' "$3"
}

render_game() {
    local i
    if ((ticks_processed == 0)); then
        if ((food_x >= 0)); then draw_at "$food_x" "$food_y" '*'; fi
        for ((i=worm_len-1; i>0; i--)); do
            draw_at "${worm_x[i]}" "${worm_y[i]}" '○'
        done
    else
        # Only three cells need repainting. Redrawing a long worm is expensive.
        if (( !grew )); then draw_at "$last_tail_x" "$last_tail_y" ' '; fi
        draw_at "${worm_x[1]}" "${worm_y[1]}" '○'
        if ((grew && food_x >= 0)); then draw_at "$food_x" "$food_y" '*'; fi
    fi
    draw_at "${worm_x[0]}" "${worm_y[0]}" '●'
    if ((grew)); then
        tput cup $((height + 2)) 7
        printf '%-6s' "$score"
    fi
}

place_food() {
    # Choose a free square directly. A full board must not spin for ever.
    local -A occupied=()
    local i x y free choice
    for ((i=0; i<worm_len; i++)); do
        occupied["${worm_x[i]},${worm_y[i]}"]=1
    done
    free=$((width * height - ${#occupied[@]}))
    if ((free <= 0)); then
        food_x=-1 food_y=-1
        return 1
    fi
    choice=$((RANDOM % free))
    for ((y=0; y<height; y++)); do
        for ((x=0; x<width; x++)); do
            [[ -v occupied["$x,$y"] ]] && continue
            if ((choice == 0)); then
                food_x=$x food_y=$y
                return 0
            fi
            choice=$((choice - 1))
        done
    done
    return 1
}

queue_direction() {
    local requested=$1
    # Compare with the actual direction, not an uncommitted key press.
    # Only one turn is applied per physics tick.
    (( (requested + 2) % 4 == dir )) && return 0
    pending_dir=$requested
}

process_input() {
    case "$1" in
        w|W|$'\e[A'|$'\eOA') queue_direction 3 ;;
        s|S|$'\e[B'|$'\eOB') queue_direction 1 ;;
        a|A|$'\e[D'|$'\eOD') queue_direction 2 ;;
        d|D|$'\e[C'|$'\eOC') queue_direction 0 ;;
        q|Q) quit_requested=1; game_over=1 ;;
    esac
}

read_input() {
    local key part last status
    if IFS= read -rsn1 -t 0.02 key; then
        if [[ $key == $'\e' ]]; then
            # Both CSI and SS3 arrow sequences occur in real terminals.
            if IFS= read -rsn1 -t 0.01 part && [[ $part == '[' || $part == O ]]; then
                if IFS= read -rsn1 -t 0.01 last; then
                    process_input "$key$part$last"
                fi
            fi
        else
            process_input "$key"
        fi
    else
        status=$?
        # Bash read returns >128 for a timeout and 1 for EOF.
        if ((status == 1)); then quit_requested=1; game_over=1; fi
    fi
}

game_tick() {
    moved=0
    ((game_over)) && return 0
    if ((pending_dir >= 0)); then
        dir=$pending_dir
        pending_dir=-1
    fi
    local new_x=${worm_x[0]} new_y=${worm_y[0]}
    case $dir in
        0) new_x=$((new_x + 1)) ;;
        1) new_y=$((new_y + 1)) ;;
        2) new_x=$((new_x - 1)) ;;
        3) new_y=$((new_y - 1)) ;;
    esac
    if ((new_x < 0 || new_x >= width || new_y < 0 || new_y >= height)); then
        game_over=1
        return 0
    fi

    grew=0
    if ((new_x == food_x && new_y == food_y)); then grew=1; fi

    # The tail vacates its square on a normal move, but not on growth.
    local i body_limit=$((worm_len - 1 + grew))
    for ((i=0; i<body_limit; i++)); do
        if ((new_x == worm_x[i] && new_y == worm_y[i])); then
            game_over=1
            return 0
        fi
    done

    last_tail_x=${worm_x[worm_len-1]}
    last_tail_y=${worm_y[worm_len-1]}
    if ((grew)); then
        ((worm_len+=1))
        ((score+=10))
    fi
    for ((i=worm_len-1; i>0; i--)); do
        worm_x[i]=${worm_x[i-1]}
        worm_y[i]=${worm_y[i-1]}
    done
    worm_x[0]=$new_x worm_y[0]=$new_y
    moved=1

    # Food is placed after the head moves. It cannot appear beneath the head.
    if ((grew)); then
        if ! place_food; then won=1; game_over=1; fi
    fi
}

clock_us() {
    local stamp=$EPOCHREALTIME
    now_us=$(( ${stamp%.*} * 1000000 + 10#${stamp#*.} ))
}

advance_due_ticks() {
    local now=$1 steps=0
    # Rebase after backwards clock changes; never wait for yesterday to catch up.
    if ((last_clock_us > 0 && now < last_clock_us)); then
        next_tick_us=$((now + TICK_US))
        last_clock_us=$now
        return 0
    fi
    last_clock_us=$now
    # Bound catch-up after a suspended terminal.
    if ((next_tick_us == 0)); then
        next_tick_us=$((now + TICK_US))
        return 0
    fi
    while ((now >= next_tick_us && steps < MAX_CATCHUP && !game_over)); do
        game_tick
        ((ticks_processed+=1))
        ((steps+=1))
        if ((moved)) && [[ ${WORM_TEST_MODE:-0} != 1 ]]; then render_game; fi
        ((next_tick_us+=TICK_US))
    done
    if ((now >= next_tick_us)); then next_tick_us=$((now + TICK_US)); fi
}

cleanup() {
    local status=$?
    trap - EXIT INT TERM HUP
    tput cnorm 2>/dev/null || true
    tput rmcup 2>/dev/null || true
    if [[ -n ${original_stty:-} ]]; then stty "$original_stty" 2>/dev/null || true; fi
    if ((status == 0)); then printf '\nThanks for playing!\n'; fi
    return "$status"
}

main() {
    if [[ ! -t 0 || ! -t 1 ]]; then
        printf 'Worm needs an interactive terminal.\n' >&2
        return 1
    fi
    if [[ -z ${EPOCHREALTIME:-} ]]; then
        printf 'Worm requires Bash 5 or later.\n' >&2
        return 1
    fi
    # The EXIT trap needs the saved state after main returns.
    original_stty=$(stty -g) || return 1
    trap cleanup EXIT
    trap 'exit 130' INT
    trap 'exit 143' TERM
    trap 'exit 129' HUP
    stty -echo -icanon min 1 time 0 || return 1
    tput smcup 2>/dev/null || true
    tput civis 2>/dev/null || true

    reset_game_state
    init_scores || return 1
    show_high_scores || return 0
    draw_border
    place_food || return 1
    render_game
    clock_us
    next_tick_us=$((now_us + TICK_US))
    while (( !game_over )); do
        read_input
        ((game_over)) && break
        clock_us
        advance_due_ticks "$now_us"
    done
    ((quit_requested)) && return 0

    tput cup $((height / 2)) $((width / 2 - 5))
    if ((won)); then printf 'YOU WIN!'; else printf 'GAME OVER'; fi
    tput cup $((height / 2 + 1)) $((width / 2 - 8))
    printf 'Final Score: %s' "$score"

    local lowest_score
    lowest_score=$(tail -1 "$SCORE_FILE" 2>/dev/null | awk '{print $2}')
    lowest_score=${lowest_score:-0}
    if ((score > lowest_score || $(wc -l < "$SCORE_FILE") < 10)); then
        tput cup $((height / 2 + 3)) $((width / 2 - 10))
        printf 'NEW HIGH SCORE!\n'
        tput cup $((height / 2 + 4)) $((width / 2 - 10))
        printf 'Enter name (8 chars): '
        stty echo icanon || return 1
        local player_name
        IFS= read -r player_name || return 0
        stty -echo -icanon min 1 time 0 || return 1
        player_name=${player_name:0:8}
        player_name=${player_name//[^[:alnum:]_-]/_}
        [[ -n $player_name ]] || player_name=Anonymous
        save_high_score "$player_name" "$score" || return 1
    fi
    show_high_scores || return 0
}

if [[ ${WORM_TEST_MODE:-0} != 1 ]]; then main "$@"; fi
