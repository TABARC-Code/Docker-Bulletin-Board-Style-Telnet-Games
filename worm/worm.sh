#!/usr/bin/env bash
# Worm - Classic ASCII Snake Game
# Recreated from late-night server rummaging energy.
# No frameworks, no dependencies, just bash and pedantic  stubbornness.

## Tabarc-Code 
# Scores: ephemeral by default, configurable if you want "server history".
: "${SCORE_FILE:=/tmp/.worm_scores}"

# Terminal setup
# Raw-ish input, no echo, non-blocking reads.
stty -echo -icanon time 0 min 0

# Alternate screen so we don't graffiti the user's scrollback.
# If this fails (some terminals are "special"), we carry on anyway.
tput smcup 2>/dev/null || true
tput civis 2>/dev/null || true

cleanup() {
    # Put everything back like we weren't here.
    tput cnorm 2>/dev/null || true
    tput rmcup 2>/dev/null || true
    stty sane
    clear
    echo "Thanks for playing! (This game was never here...)"
    exit 0
}

trap cleanup EXIT INT TERM

# Game variables (chosen by feel, not science)
width=60
height=20
score=0
game_over=0

# Worm starts centre-ish
worm_x=(30 29 28)
worm_y=(10 10 10)
worm_len=3

# Direction: 0=right, 1=down, 2=left, 3=up
dir=0

# Precompute border strings so we're not forking seq like it's 1999.
hline="$(printf '%*s' "$width" '' | tr ' ' '─')"
blank="$(printf '%*s' "$width" '')"

init_scores() {
    [[ -f "$SCORE_FILE" ]] && return
    cat > "$SCORE_FILE" <<EOF
Snake 500
Worm 300
Player 150
EOF
}

save_high_score() {
    local name=$1 pts=$2
    echo "$name $pts" >> "$SCORE_FILE"
    sort -k2 -rn "$SCORE_FILE" | head -10 > "${SCORE_FILE}.tmp"
    mv "${SCORE_FILE}.tmp" "$SCORE_FILE"
}

show_high_scores() {
    clear
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                    WORM HIGH SCORES                        ║"
    echo "╠════════════════════════════════════════════════════════════╣"

    local rank=1
    while read -r name pts; do
        printf "║ %2d. %-30s %20s ║\n" "$rank" "$name" "$pts"
        ((rank++))
    done < "$SCORE_FILE"

    echo "╚════════════════════════════════════════════════════════════╝"
    echo
    echo "Press any key to start..."
    read -n1 -s
}

draw_border() {
    clear
    echo "┌$hline┐"
    for ((i=0;i<height;i++)); do
        echo "│$blank│"
    done
    echo "└$hline┘"

    tput cup $((height + 2)) 0
    echo "Score: $score | WASD/Arrows to move | Q to quit"
    tput cup 0 $((width + 5))
    echo "[ WORM v1.3 ]"
}

draw_at() {
    local x=$1 y=$2 char=$3
    tput cup $((y + 1)) $((x + 1))
    echo -n "$char"
}

worm_occupies() {
    local x=$1 y=$2
    for ((i=0;i<worm_len;i++)); do
        [[ ${worm_x[$i]} -eq $x && ${worm_y[$i]} -eq $y ]] && return 0
    done
    return 1
}

place_food() {
    # Avoid spawning inside the worm.
    # Tiny loop. Cheap insurance.
    local x y
    while :; do
        x=$((RANDOM % (width - 2) + 1))
        y=$((RANDOM % (height - 2) + 1))
        worm_occupies "$x" "$y" || { food_x=$x; food_y=$y; return; }
    done
}

check_self_collision() {
    local hx=${worm_x[0]} hy=${worm_y[0]}
    for ((i=1;i<worm_len;i++)); do
        [[ ${worm_x[$i]} -eq $hx && ${worm_y[$i]} -eq $hy ]] && return 0
    done
    return 1
}

# Init
init_scores
show_high_scores
draw_border
place_food

# Initial draw so you don't start on a blank screen.
draw_at "$food_x" "$food_y" "*"
draw_at "${worm_x[0]}" "${worm_y[0]}" "●"
for ((i=1;i<worm_len;i++)); do
    draw_at "${worm_x[$i]}" "${worm_y[$i]}" "○"
done

while [[ $game_over -eq 0 ]]; do
    # Read input with timeout.
    read -s -n1 -t 0.1 key

    # Arrow keys arrive as ESC + [X.
    # We eat the ESC, then read the next two.
    if [[ $key == $'\e' ]]; then
        read -s -n2 -t 0.01 key
    fi

    case "$key" in
        w|W|'[A') [[ $dir -ne 1 ]] && dir=3 ;;
        s|S|'[B') [[ $dir -ne 3 ]] && dir=1 ;;
        a|A|'[D') [[ $dir -ne 0 ]] && dir=2 ;;
        d|D|'[C') [[ $dir -ne 2 ]] && dir=0 ;;
        q|Q) game_over=1 ;;
    esac

    new_x=${worm_x[0]}
    new_y=${worm_y[0]}

    case $dir in
        0) ((new_x++)) ;;
        1) ((new_y++)) ;;
        2) ((new_x--)) ;;
        3) ((new_y--)) ;;
    esac

    # Walls are instant death. No wrapping. No mercy.
    if [[ $new_x -lt 0 || $new_x -ge $width || $new_y -lt 0 || $new_y -ge $height ]]; then
        game_over=1
        continue
    fi

    ate_food=0
    if [[ $new_x -eq $food_x && $new_y -eq $food_y ]]; then
        ate_food=1
        ((score += 10))
        ((worm_len++))
        place_food
    fi

    # Erase tail if not eating (growth is just "don't delete last segment").
    if [[ $ate_food -eq 0 ]]; then
        draw_at "${worm_x[$((worm_len - 1))]}" "${worm_y[$((worm_len - 1))]}" " "
    fi

    # Shift body back
    for ((i=worm_len-1;i>0;i--)); do
        worm_x[$i]=${worm_x[$((i - 1))]}
        worm_y[$i]=${worm_y[$((i - 1))]}
    done

    worm_x[0]=$new_x
    worm_y[0]=$new_y

    check_self_collision && game_over=1 && continue

    # Draw food + worm
    draw_at "$food_x" "$food_y" "*"
    draw_at "${worm_x[0]}" "${worm_y[0]}" "●"
    for ((i=1;i<worm_len;i++)); do
        draw_at "${worm_x[$i]}" "${worm_y[$i]}" "○"
    done

    # Score display
    tput cup $((height + 2)) 7
    printf "%-6s" "$score"

    sleep 0.08
done

# Game over
tput cup $((height / 2)) $((width / 2 - 5))
echo "GAME OVER"
tput cup $((height / 2 + 1)) $((width / 2 - 8))
echo "Final Score: $score"

lowest_score=$(tail -1 "$SCORE_FILE" 2>/dev/null | awk '{print $2}')
lowest_score=${lowest_score:-0}

if [[ $score -gt $lowest_score ]] || [[ $(wc -l < "$SCORE_FILE") -lt 10 ]]; then
    tput cup $((height / 2 + 3)) $((width / 2 - 10))
    echo "NEW HIGH SCORE!"
    tput cup $((height / 2 + 4)) $((width / 2 - 10))
    echo -n "Enter name (8 chars): "

    # Temporarily re-enable echo for name entry.
    stty echo icanon
    read -n8 player_name
    stty -echo -icanon time 0 min 0

    [[ -z "$player_name" ]] && player_name="Anonymous"
    save_high_score "$player_name" "$score"
fi

sleep 2
show_high_scores
