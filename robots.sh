#!/usr/bin/env bash
# Robots - Strategic ASCII dodging game
# BSD classic, recreated from memory.
#

# It's a puzzle game wearing an arcade game's coat. Go with it
# The robots are stupid. So are we, if we underestimate them.

: "${SCORE_FILE:=/tmp/.robots_scores}"

# Terminal setup: raw-ish input, no echo.
stty -echo -icanon time 0 min 0

# Alternate screen buffer so we don't graffiti scrollback.
# If your terminal doesn't support this, it'll just ignore it (like most people).
tput smcup 2>/dev/null || true
tput civis 2>/dev/null || true

cleanup() {
    tput cnorm 2>/dev/null || true
    tput rmcup 2>/dev/null || true
    stty sane
    clear
    echo "Shutting down robot arena..."
    exit 0
}

trap cleanup EXIT INT TERM

# Game state
width=50
height=20
score=0
level=1
game_over=0
teleports_left=3

# Precompute border strings so we don't fork `seq` like it's free.
# Spoiler: it isn't, especially over telnet.
hline="$(printf '%*s' "$width" '' | tr ' ' '═')"
blank="$(printf '%*s' "$width" '')"

# Player position
player_x=25
player_y=10

# Robot and junk arrays
declare -a robot_x
declare -a robot_y
declare -a junk_x
declare -a junk_y

init_scores() {
    if [[ ! -f "$SCORE_FILE" ]]; then
        cat > "$SCORE_FILE" <<EOF
Skynet 10000
HAL9000 7500
Robocop 5000
EOF
    fi
}

save_high_score() {
    local name=$1
    local pts=$2   # don't shadow global score; future-you will swear at present-you
    echo "$name $pts" >> "$SCORE_FILE"
    sort -k2 -rn "$SCORE_FILE" | head -10 > "${SCORE_FILE}.tmp"
    mv "${SCORE_FILE}.tmp" "$SCORE_FILE"
}

show_high_scores() {
    clear
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║                  ROBOTS HIGH SCORES                    ║"
    echo "╠════════════════════════════════════════════════════════╣"

    local rank=1
    while read -r name pts; do
        printf "║ %2d. %-30s %15s ║\n" "$rank" "$name" "$pts"
        ((rank++))
    done < "$SCORE_FILE"

    echo "╚════════════════════════════════════════════════════════╝"
    echo
    echo "OBJECTIVE: Dodge robots and make them crash."
    echo "Robots move towards you each turn. Predictable. Relentless. Like debt."
    echo "T = teleport (limited), W = wait, Q = quit."
    echo
    echo "Press any key to start..."
    read -n1 -s
}

init_level() {
    local num_robots=$((5 + level * 2))

    robot_x=()
    robot_y=()

    # Deliberate choice: junk persists between levels.
    # It's either "rising difficulty" or "I couldn't be bothered", depending on your mood.
    # If you want clean boards per level, uncomment these:
    # junk_x=()
    # junk_y=()

    for ((i=0; i<num_robots; i++)); do
        local rx=$((RANDOM % width))
        local ry=$((RANDOM % height))

        # Don't spawn on player (the game has standards, just not many).
        while [[ $rx -eq $player_x && $ry -eq $player_y ]]; do
            rx=$((RANDOM % width))
            ry=$((RANDOM % height))
        done

        robot_x+=("$rx")
        robot_y+=("$ry")
    done

    teleports_left=$((3 + level / 3))
}

draw_board() {
    clear

    echo "╔${hline}╗"
    for ((i=0; i<height; i++)); do
        echo "║${blank}║"
    done
    echo "╚${hline}╝"

    tput cup $((height + 2)) 0
    echo "Level: $level | Score: $score | Teleports: $teleports_left | Robots: ${#robot_x[@]}"
    tput cup $((height + 3)) 0
    echo "[YUHJKLBN]=Move  [W]=Wait  [T]=Teleport  [Q]=Quit"
    tput cup $((height + 4)) 0
    echo "Legend: @ = You  + = Robot  * = Junk"
    tput cup $((height + 5)) 0
    echo "Y K U"
    tput cup $((height + 6)) 0
    echo "H-@-L"
    tput cup $((height + 7)) 0
    echo "B J N"
}

draw_at() {
    local x=$1
    local y=$2
    local char=$3
    tput cup $((y + 1)) $((x + 1))
    echo -n "$char"
}

clear_at() {
    draw_at "$1" "$2" " "
}

draw_all() {
    # Brutal redraw. Works fine locally. Over telnet it can look like a strobe light.
    # If you want fancy diff-based drawing, you're in the wrong decade. I need coffee
    for ((i=0; i<width; i++)); do
        for ((j=0; j<height; j++)); do
            clear_at "$i" "$j"
        done
    done

    for ((i=0; i<${#junk_x[@]}; i++)); do
        draw_at "${junk_x[$i]}" "${junk_y[$i]}" "*"
    done

    for ((i=0; i<${#robot_x[@]}; i++)); do
        draw_at "${robot_x[$i]}" "${robot_y[$i]}" "+"
    done

    draw_at "$player_x" "$player_y" "@"
}

move_robots() {
    local new_robot_x=()
    local new_robot_y=()

    for ((i=0; i<${#robot_x[@]}; i++)); do
        local rx=${robot_x[$i]}
        local ry=${robot_y[$i]}

        # Move towards player
        [[ $rx -lt $player_x ]] && ((rx++))
        [[ $rx -gt $player_x ]] && ((rx--))
        [[ $ry -lt $player_y ]] && ((ry++))
        [[ $ry -gt $player_y ]] && ((ry--))

        # Crash into junk?
        local hit_junk=0
        for ((j=0; j<${#junk_x[@]}; j++)); do
            if [[ $rx -eq ${junk_x[$j]} && $ry -eq ${junk_y[$j]} ]]; then
                hit_junk=1
                break
            fi
        done

        [[ $hit_junk -eq 0 ]] && { new_robot_x+=("$rx"); new_robot_y+=("$ry"); }
    done

    # Robot-robot collisions (any shared cell becomes junk)
    local final_robot_x=()
    local final_robot_y=()

    for ((i=0; i<${#new_robot_x[@]}; i++)); do
        local rx=${new_robot_x[$i]}
        local ry=${new_robot_y[$i]}
        local count=1

        for ((j=i+1; j<${#new_robot_x[@]}; j++)); do
            if [[ $rx -eq ${new_robot_x[$j]} && $ry -eq ${new_robot_y[$j]} ]]; then
                ((count++))
            fi
        done

        if [[ $count -eq 1 ]]; then
            # only keep it if no one else landed here
            local unique=1
            for ((j=0; j<${#final_robot_x[@]}; j++)); do
                if [[ $rx -eq ${final_robot_x[$j]} && $ry -eq ${final_robot_y[$j]} ]]; then
                    unique=0
                    break
                fi
            done
            [[ $unique -eq 1 ]] && { final_robot_x+=("$rx"); final_robot_y+=("$ry"); }
        fi
    done

    # Any position in new_robot_* that isn't in final_robot_* is a crash site. Damm 3am
    local crashes=$((${#new_robot_x[@]} - ${#final_robot_x[@]}))
    if [[ $crashes -gt 0 ]]; then
        ((score += crashes * 10))

        for ((i=0; i<${#new_robot_x[@]}; i++)); do
            local rx=${new_robot_x[$i]}
            local ry=${new_robot_y[$i]}
            local survived=0

            for ((j=0; j<${#final_robot_x[@]}; j++)); do
                if [[ $rx -eq ${final_robot_x[$j]} && $ry -eq ${final_robot_y[$j]} ]]; then
                    survived=1
                    break
                fi
            done

            if [[ $survived -eq 0 ]]; then
                draw_at "$rx" "$ry" "#"
                junk_x+=("$rx")
                junk_y+=("$ry")
            fi
        done

        sleep 0.2
    fi

    robot_x=("${final_robot_x[@]}")
    robot_y=("${final_robot_y[@]}")

    # Did a robot reach the player?
    for ((i=0; i<${#robot_x[@]}; i++)); do
        if [[ ${robot_x[$i]} -eq $player_x && ${robot_y[$i]} -eq $player_y ]]; then
            game_over=1
            return
        fi
    done

    # Level complete
    if [[ ${#robot_x[@]} -eq 0 ]]; then
        ((score += level * 50))
        ((level++))
        sleep 0.3
        init_level
    fi
}

teleport() {
    [[ $teleports_left -gt 0 ]] || return
    ((teleports_left--))

    local safe=0
    while [[ $safe -eq 0 ]]; do
        player_x=$((RANDOM % width))
        player_y=$((RANDOM % height))
        safe=1

        for ((i=0; i<${#robot_x[@]}; i++)); do
            if [[ ${robot_x[$i]} -eq $player_x && ${robot_y[$i]} -eq $player_y ]]; then
                safe=0
                break
            fi
        done

        for ((i=0; i<${#junk_x[@]}; i++)); do
            if [[ ${junk_x[$i]} -eq $player_x && ${junk_y[$i]} -eq $player_y ]]; then
                safe=0
                break
            fi
        done
    done
}

# Main
init_scores
show_high_scores

init_level
draw_board
draw_all

while [[ $game_over -eq 0 ]]; do
    # HUD refresh (cheap)
    tput cup $((height + 2)) 8
    printf "%-4s" "$level"
    tput cup $((height + 2)) 18
    printf "%-10s" "$score"
    tput cup $((height + 2)) 36
    printf "%-3s" "$teleports_left"
    tput cup $((height + 2)) 51
    printf "%-4s" "${#robot_x[@]}"

    read -s -n1 key

    local old_x=$player_x
    local old_y=$player_y
    local moved=0

    case "$key" in
        y|Y) ((player_x--)); ((player_y--)); moved=1 ;;
        k|K) ((player_y--)); moved=1 ;;
        u|U) ((player_x++)); ((player_y--)); moved=1 ;;
        h|H) ((player_x--)); moved=1 ;;
        l|L) ((player_x++)); moved=1 ;;
        b|B) ((player_x--)); ((player_y++)); moved=1 ;;
        j|J) ((player_y++)); moved=1 ;;
        n|N) ((player_x++)); ((player_y++)); moved=1 ;;
        w|W) moved=1 ;;
        t|T) teleport; moved=1 ;;
        q|Q) game_over=1 ;;
    esac

    if [[ $moved -eq 1 ]]; then
        # Bounds check
        if [[ $player_x -lt 0 || $player_x -ge $width || $player_y -lt 0 || $player_y -ge $height ]]; then
            player_x=$old_x
            player_y=$old_y
        else
            # Junk collision blocks movement
            for ((i=0; i<${#junk_x[@]}; i++)); do
                if [[ ${junk_x[$i]} -eq $player_x && ${junk_y[$i]} -eq $player_y ]]; then
                    player_x=$old_x
                    player_y=$old_y
                    break
                fi
            done
        fi

        move_robots
        draw_all
    fi
done

# Game over
draw_all
draw_at "$player_x" "$player_y" "X"

tput cup $((height / 2)) $((width / 2 - 5))
echo "DESTROYED!"
tput cup $((height / 2 + 1)) $((width / 2 - 9))
echo "Final Score: $score"
tput cup $((height / 2 + 2)) $((width / 2 - 9))
echo "Level Reached: $level"

lowest_score=$(tail -1 "$SCORE_FILE" 2>/dev/null | awk '{print $2}')
lowest_score=${lowest_score:-0}

if [[ $score -gt $lowest_score ]] || [[ $(wc -l < "$SCORE_FILE") -lt 10 ]]; then
    tput cup $((height / 2 + 4)) $((width / 2 - 12))
    echo "NEW HIGH SCORE!"
    tput cup $((height / 2 + 5)) $((width / 2 - 12))
    echo -n "Enter name (8 chars): "

    stty echo icanon
    read -n8 player_name
    stty -echo -icanon time 0 min 0

    [[ -z "$player_name" ]] && player_name="Anonymous"
    save_high_score "$player_name" "$score"
fi

sleep 2
show_high_scores
