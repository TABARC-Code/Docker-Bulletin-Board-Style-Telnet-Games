#!/usr/bin/env bash
# Pinball - ASCII pinball with physics
# Recreated from a Unix box, circa 1995 
#
# No graphics. No sound. Just the raw shame of missing a flipper timing window.

: "${SCORE_FILE:=/tmp/.pinball_scores}"

# Terminal setup: raw-ish input, no echo, non-blocking reads.
stty -echo -icanon time 0 min 0

# Alternate screen buffer so we don't scribble over scrollback like an animal.
tput smcup 2>/dev/null || true
tput civis 2>/dev/null || true

cleanup() {
    tput cnorm 2>/dev/null || true
    tput rmcup 2>/dev/null || true
    stty sane
    clear
    echo "Game over. See you next time..."
    exit 0
}

trap cleanup EXIT INT TERM

# Game state
width=40
height=25
score=0
balls_left=3
ball_in_play=0
game_over=0
combo=0

# Ball physics
ball_x=20
ball_y=20
ball_vx=0
ball_vy=0

# Flippers (TTL keeps them active for a short time without blocking input)
left_flipper_ttl=0
right_flipper_ttl=0
flipper_ttl_max=2   # frames, not seconds. feels right. don't overthink it.

# Board strings (avoid seq spam, forks are for people with spare CPU cycles)
hline="$(printf '%*s' "$width" '' | tr ' ' '═')"
blank="$(printf '%*s' "$width" '')"

# Bumpers (x, y, points)
declare -a bumpers=(
    "10 8 100"
    "20 6 100"
    "30 8 100"
    "15 12 50"
    "25 12 50"
)

# Bumper flash timers (same index as bumpers)
declare -a bumper_flash=()
for _ in "${bumpers[@]}"; do bumper_flash+=(0); done

# Targets (x, y, hit)
declare -a targets=(
    "5 10 0"
    "35 10 0"
    "8 15 0"
    "32 15 0"
)

init_scores() {
    [[ -f "$SCORE_FILE" ]] && return
    cat > "$SCORE_FILE" <<EOF
Anonymous 5000
Guest 3000
Player 1500
EOF
}

save_high_score() {
    local name=$1
    local pts=$2  # don't shadow global score, it's confusing and you will forget
    echo "$name $pts" >> "$SCORE_FILE"
    sort -k2 -rn "$SCORE_FILE" | head -10 > "${SCORE_FILE}.tmp"
    mv "${SCORE_FILE}.tmp" "$SCORE_FILE"
}

show_high_scores() {
    clear
    echo "╔════════════════════════════════════════╗"
    echo "║            PINBALL HIGH SCORES         ║"
    echo "╠════════════════════════════════════════╣"

    local rank=1
    while read -r name pts; do
        printf "║ %2d. %-20s %10s ║\n" "$rank" "$name" "$pts"
        ((rank++))
    done < "$SCORE_FILE"

    echo "╚════════════════════════════════════════╝"
    echo
    echo "Press any key to continue..."
    read -n1 -s
}

draw_flippers() {
    # Left flipper zone
    tput cup $((height)) $((width/4))
    if [[ $left_flipper_ttl -gt 0 ]]; then
        echo -n "╱──"
    else
        echo -n "───"
    fi

    # Right flipper zone
    tput cup $((height)) $((width*3/4 - 2))
    if [[ $right_flipper_ttl -gt 0 ]]; then
        echo -n "──╲"
    else
        echo -n "───"
    fi
}

draw_ball() {
    [[ $ball_in_play -eq 1 ]] || return
    tput cup $((ball_y + 1)) $((ball_x + 1))
    echo -n "●"
}

erase_ball() {
    tput cup $((ball_y + 1)) $((ball_x + 1))
    echo -n " "
}

draw_board() {
    clear
    echo "╔${hline}╗"
    for ((i=0;i<height;i++)); do
        echo "║${blank}║"
    done
    echo "╚${hline}╝"

    tput cup $((height + 2)) 0
    echo "Score: $score | Balls: $balls_left | Combo: x${combo}"
    tput cup $((height + 3)) 0
    echo "[A]=Left Flipper [D]=Right Flipper [SPACE]=Launch [Q]=Quit"

    # Launch chute (right side)
    for ((i=height-5; i<height; i++)); do
        tput cup $((i + 1)) $((width))
        echo -n "│"
    done

    # Bumpers
    for i in "${!bumpers[@]}"; do
        read -r bx by pts <<< "${bumpers[$i]}"
        tput cup $((by + 1)) $((bx + 1))
        echo -n "◉"
        bumper_flash[$i]=0
    done

    # Targets
    for i in "${!targets[@]}"; do
        read -r tx ty hit <<< "${targets[$i]}"
        tput cup $((ty + 1)) $((tx + 1))
        if [[ $hit -eq 0 ]]; then
            echo -n "▓"
        else
            echo -n "░"
        fi
    done

    draw_flippers
}

launch_ball() {
    if [[ $ball_in_play -eq 0 && $balls_left -gt 0 ]]; then
        # Start in the chute
        ball_x=$((width - 2))
        ball_y=$((height - 3))
        ball_vx=-2
        ball_vy=-3
        ball_in_play=1
        combo=1
    fi
}

clamp_velocities() {
    # This isn't a physics engine. It's a bash script pretending. I kept it veryy 1990's
    [[ $ball_vx -gt 3 ]] && ball_vx=3
    [[ $ball_vx -lt -3 ]] && ball_vx=-3
    [[ $ball_vy -gt 5 ]] && ball_vy=5
    [[ $ball_vy -lt -5 ]] && ball_vy=-5
}

tick_bumper_flash() {
    # If a bumper flashed, revert it back to ◉ after a couple frames.
    for i in "${!bumpers[@]}"; do
        if [[ ${bumper_flash[$i]} -gt 0 ]]; then
            ((bumper_flash[$i]--))
            if [[ ${bumper_flash[$i]} -eq 0 ]]; then
                read -r bx by pts <<< "${bumpers[$i]}"
                tput cup $((by + 1)) $((bx + 1))
                echo -n "◉"
            fi
        fi
    done
}

check_bumpers() {
    for i in "${!bumpers[@]}"; do
        read -r bx by pts <<< "${bumpers[$i]}"

        local dx=$((ball_x - bx))
        local dy=$((ball_y - by))

        if [[ $dx -ge -1 && $dx -le 1 && $dy -ge -1 && $dy -le 1 ]]; then
            ((score += pts * combo))
            ((combo++))

            # Bounce with tiny randomness so it doesn't loop forever.
            ball_vx=$((-ball_vx + (RANDOM % 3 - 1)))
            ball_vy=$((-ball_vy + (RANDOM % 3 - 1)))
            clamp_velocities

            # Flash bumper
            tput cup $((by + 1)) $((bx + 1))
            echo -n "◎"
            bumper_flash[$i]=2
            return 0
        fi
    done
    return 1
}

check_targets() {
    for i in "${!targets[@]}"; do
        read -r tx ty hit <<< "${targets[$i]}"

        if [[ $ball_x -eq $tx && $ball_y -eq $ty && $hit -eq 0 ]]; then
            targets[$i]="$tx $ty 1"
            ((score += 250 * combo))
            ((combo++))
            ball_vx=$((-ball_vx))
            clamp_velocities

            # Check all targets hit
            local all_hit=1
            for target in "${targets[@]}"; do
                read -r _ _ h <<< "$target"
                [[ $h -eq 0 ]] && all_hit=0
            done

            if [[ $all_hit -eq 1 ]]; then
                ((score += 1000))
                targets=(
                    "5 10 0"
                    "35 10 0"
                    "8 15 0"
                    "32 15 0"
                )
            fi

            # Redraw targets (cheap and simple)
            for j in "${!targets[@]}"; do
                read -r rx ry rhit <<< "${targets[$j]}"
                tput cup $((ry + 1)) $((rx + 1))
                [[ $rhit -eq 0 ]] && echo -n "▓" || echo -n "░"
            done

            return 0
        fi
    done
    return 1
}

update_hud() {
    tput cup $((height + 2)) 7
    printf "%-8s" "$score"
    tput cup $((height + 2)) 22
    printf "%-3s" "$balls_left"
    tput cup $((height + 2)) 36
    printf "x%-4s" "$combo"
}

lose_ball() {
    ball_in_play=0
    ((balls_left--))
    combo=1
    ball_vx=0
    ball_vy=0

    if [[ $balls_left -le 0 ]]; then
        game_over=1
    fi
}

update_ball() {
    [[ $ball_in_play -eq 1 ]] || return

    erase_ball

    # Gravity
    ((ball_vy++))
    [[ $ball_vy -gt 4 ]] && ball_vy=4

    # Position update
    ((ball_x += ball_vx))
    ((ball_y += ball_vy))

    # Side walls
    if [[ $ball_x -le 0 ]]; then
        ball_x=1
        ball_vx=$((-ball_vx))
    elif [[ $ball_x -ge $((width - 1)) ]]; then
        ball_x=$((width - 2))
        ball_vx=$((-ball_vx))
    fi

    # Ceiling
    if [[ $ball_y -le 0 ]]; then
        ball_y=1
        ball_vy=$((-ball_vy))
    fi

    # If we dropped below the board, we don't negotiate.
    # This fixes the "skipped past height-1" edge-case. It was an issue from previous versions. note - watch this.
    if [[ $ball_y -ge $height ]]; then
        lose_ball
        update_hud
        return
    fi

    # Bumpers + targets
    check_bumpers
    check_targets

    # Flippers live near the bottom
    if [[ $ball_y -ge $((height - 2)) ]]; then
        # Left flipper zone
        if [[ $ball_x -ge $((width/4 - 2)) && $ball_x -le $((width/4 + 2)) && $left_flipper_ttl -gt 0 ]]; then
            ball_vy=-4
            ball_vx=-2
            ((score += 10))
            clamp_velocities

        # Right flipper zone
        elif [[ $ball_x -ge $((width*3/4 - 2)) && $ball_x -le $((width*3/4 + 2)) && $right_flipper_ttl -gt 0 ]]; then
            ball_vy=-4
            ball_vx=2
            ((score += 10))
            clamp_velocities

        # Drain
        elif [[ $ball_y -ge $((height - 1)) ]]; then
            lose_ball
            update_hud
            return
        fi
    fi

    draw_ball
    tick_bumper_flash
    update_hud
}

# Main
init_scores
show_high_scores
draw_board
update_hud

while [[ $game_over -eq 0 ]]; do
    # Read input
    read -s -n1 -t 0.05 key

    case "$key" in
        a|A)
            left_flipper_ttl=$flipper_ttl_max
            ;;
        d|D)
            right_flipper_ttl=$flipper_ttl_max
            ;;
        " ")
            launch_ball
            ;;
        q|Q)
            game_over=1
            ;;
    esac

    # Decay flippers (non-blocking, no sleeps mid-input)
    local_redraw=0
    if [[ $left_flipper_ttl -gt 0 ]]; then
        ((left_flipper_ttl--))
        local_redraw=1
    fi
    if [[ $right_flipper_ttl -gt 0 ]]; then
        ((right_flipper_ttl--))
        local_redraw=1
    fi
    [[ $local_redraw -eq 1 ]] && draw_flippers

    update_ball

    # Frame pacing: not a promise, just a suggestion.
    sleep 0.03
done

# Game over screen
tput cup $((height / 2)) $((width / 2 - 5))
echo "GAME OVER"
tput cup $((height / 2 + 1)) $((width / 2 - 10))
echo "Final Score: $score"

# Check high score
lowest_score=$(tail -1 "$SCORE_FILE" 2>/dev/null | awk '{print $2}')
lowest_score=${lowest_score:-0}

if [[ $score -gt $lowest_score ]] || [[ $(wc -l < "$SCORE_FILE") -lt 10 ]]; then
    tput cup $((height / 2 + 3)) $((width / 2 - 12))
    echo "NEW HIGH SCORE!"
    tput cup $((height / 2 + 4)) $((width / 2 - 12))
    echo -n "Enter name (8 chars): "

    stty echo icanon
    read -n8 player_name
    stty -echo -icanon time 0 min 0

    [[ -z "$player_name" ]] && player_name="Anonymous"
    save_high_score "$player_name" "$score"
fi

sleep 2
show_high_scores
