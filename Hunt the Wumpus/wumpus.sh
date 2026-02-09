#!/usr/bin/env bash
# Hunt the Wumpus - Extended Edition
# 35 caves, riddles, puzzles, and an unreasonable number of ways to die.
# Based on Gregory Yob's 1973 original. Classic
#
# Death messages are loaded from a separate file now, because this is a game,
# I made the mod as it ws lagging. period..

: "${SCORE_FILE:=/tmp/.wumpus_scores}"

# Terminal setup: raw-ish input, no echo.
stty -echo -icanon time 0 min 0

# Alternate screen buffer. 
tput smcup 2>/dev/null || true
tput civis 2>/dev/null || true

cleanup() {
    tput cnorm 2>/dev/null || true
    tput rmcup 2>/dev/null || true
    stty sane
    clear
    echo "The caves fall silent once more..."
    exit 0
}

trap cleanup EXIT INT TERM

# Script directory for local assets (death_messages.txt)
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
: "${DEATH_MESSAGES_FILE:=$SCRIPT_DIR/death_messages.txt}"

# Game state
num_caves=35
player_cave=1
wumpus_cave=0
arrows_left=5
moves=0
score=1000
game_over=0
wumpus_awake=0
death_message=""

# Hazard locations
declare -a pit_caves=()
declare -a bat_caves=()
declare -a riddle_caves=()
declare -a puzzle_caves=()

# Cave network (each connects to 3 others)
declare -A cave_connections=()

# Riddles and answers
declare -A riddles=()
declare -A riddle_answers=()
declare -A puzzles=()
declare -A puzzle_answers=()
declare -a solved_riddles=()
declare -a solved_puzzles=()

# Death messages loaded from file (one per line).
# If file missing, it falls back to a small baked-in set so the script still runs.
declare -a death_messages=()

load_death_messages() {
    death_messages=()

    if [[ -r "$DEATH_MESSAGES_FILE" ]]; then
        # Read non-empty, non-comment lines.
        # mapfile is bash-only, which is fine because the script already assumes bash.
        mapfile -t death_messages < <(
            grep -v '^[[:space:]]*$' "$DEATH_MESSAGES_FILE" | grep -v '^[[:space:]]*#'
        )
    fi

    if [[ ${#death_messages[@]} -eq 0 ]]; then
        # Fallback set: short, sharp, and vaguely judgemental.
        death_messages=(
            "You died. The cave remains unimpressed."
            "The Wumpus thanks you for your donation."
            "That was optimism with consequences."
            "Room temperature achieved."
            "You've become a cautionary tale with legs. Had."
        )
    fi
}

init_riddles() {
    riddles[1]="I speak without a mouth and hear without ears. I have no body, but come alive with wind. What am I?"
    riddle_answers[1]="echo"

    riddles[2]="The more you take, the more you leave behind. What am I?"
    riddle_answers[2]="footsteps"

    riddles[3]="What has keys but no locks, space but no room, and you can enter but not go inside?"
    riddle_answers[3]="keyboard"

    riddles[4]="I am not alive, but I grow; I don't have lungs, but I need air; I don't have a mouth, but water kills me. What am I?"
    riddle_answers[4]="fire"

    riddles[5]="What can travel around the world whilst staying in a corner?"
    riddle_answers[5]="stamp"
}

init_puzzles() {
    puzzles[1]="Three switches outside a room control three lamps inside. You can flip switches but only enter ONCE. How do you determine which switch controls which lamp?|Turn on switch 1, wait 5 min, turn off. Turn on switch 2, enter. Hot bulb=1, On=2, Off=3"
    puzzle_answers[1]="heat"

    puzzles[2]="A man describes his daughters: 'They are all blonde but two, all brunette but two, all redhead but two.' How many daughters?|Three daughters"
    puzzle_answers[2]="three"

    puzzles[3]="You have 12 balls, one is slightly heavier. You have a balance scale and can use it only 3 times. Can you find the heavy ball?|Divide into groups of 4, then 3, then 1"
    puzzle_answers[3]="yes"

    puzzles[4]="A farmer needs to cross a river with a fox, chicken, and grain. Boat holds one item. Fox eats chicken, chicken eats grain. How?|Take chicken, return. Take fox, return with chicken. Take grain, return. Take chicken"
    puzzle_answers[4]="chicken"
}

init_scores() {
    [[ -f "$SCORE_FILE" ]] && return
    cat > "$SCORE_FILE" <<EOF
Holmes 5000
Poirot 3500
Marple 2000
EOF
}

save_high_score() {
    local name=$1
    local pts=$2  # don't shadow global score; it's how the bugs breed
    echo "$name $pts" >> "$SCORE_FILE"
    sort -k2 -rn "$SCORE_FILE" | head -10 > "${SCORE_FILE}.tmp"
    mv "${SCORE_FILE}.tmp" "$SCORE_FILE"
}the 

show_high_scores() {
    clear
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║         HUNT THE WUMPUS - HALL OF HUNTERS              ║"
    echo "╠════════════════════════════════════════════════════════╣"

    local rank=1
    while read -r name pts; do
        printf "║ %2d. %-30s %15s ║\n" "$rank" "$name" "$pts"
        ((rank++))
    done < "$SCORE_FILE"

    echo "╚════════════════════════════════════════════════════════╝"
    echo
    echo "35 interconnected caves. Pits. Bats. Riddles. Puzzles."
    echo "5 crooked arrows. One Wumpus. Absolute Zero sympathy."
    echo
    echo "Press any key to enter the caves..."
    read -n1 -s
}

generate_caves() {
    cave_connections[1]="2,5,8"
    cave_connections[2]="1,3,10"
    cave_connections[3]="2,4,12"
    cave_connections[4]="3,5,14"
    cave_connections[5]="1,4,16"
    cave_connections[6]="7,17,18"
    cave_connections[7]="6,8,19"
    cave_connections[8]="1,7,20"
    cave_connections[9]="10,21,22"
    cave_connections[10]="2,9,23"
    cave_connections[11]="12,24,25"
    cave_connections[12]="3,11,26"
    cave_connections[13]="14,27,28"
    cave_connections[14]="4,13,29"
    cave_connections[15]="16,30,31"
    cave_connections[16]="5,15,32"
    cave_connections[17]="6,18,33"
    cave_connections[18]="6,17,19"
    cave_connections[19]="7,18,20"
    cave_connections[20]="8,19,21"
    cave_connections[21]="9,20,22"
    cave_connections[22]="9,21,23"
    cave_connections[23]="10,22,24"
    cave_connections[24]="11,23,25"
    cave_connections[25]="11,24,26"
    cave_connections[26]="12,25,27"
    cave_connections[27]="13,26,28"
    cave_connections[28]="13,27,29"
    cave_connections[29]="14,28,30"
    cave_connections[30]="15,29,31"
    cave_connections[31]="15,30,32"
    cave_connections[32]="16,31,33"
    cave_connections[33]="17,32,34"
    cave_connections[34]="33,35,1"
    cave_connections[35]="34,2,3"
}

place_hazards() {
    pit_caves=(); bat_caves=(); riddle_caves=(); puzzle_caves=()
    solved_riddles=(); solved_puzzles=()

    local occupied=("$player_cave")

    # Wumpus
    while :; do
        wumpus_cave=$((RANDOM % num_caves + 1))
        [[ ! " ${occupied[*]} " =~ " ${wumpus_cave} " ]] && break
    done
    occupied+=("$wumpus_cave")

    # 3 pits
    for ((i=0; i<3; i++)); do
        while :; do
            local cave=$((RANDOM % num_caves + 1))
            [[ " ${occupied[*]} " =~ " ${cave} " ]] && continue
            pit_caves+=("$cave"); occupied+=("$cave"); break
        done
    done

    # 3 bat colonies
    for ((i=0; i<3; i++)); do
        while :; do
            local cave=$((RANDOM % num_caves + 1))
            [[ " ${occupied[*]} " =~ " ${cave} " ]] && continue
            bat_caves+=("$cave"); occupied+=("$cave"); break
        done
    done

    # 3 riddle guardians
    for ((i=0; i<3; i++)); do
        while :; do
            local cave=$((RANDOM % num_caves + 1))
            [[ " ${occupied[*]} " =~ " ${cave} " ]] && continue
            riddle_caves+=("$cave"); occupied+=("$cave"); break
        done
    done

    # 2 puzzle chambers
    for ((i=0; i<2; i++)); do
        while :; do
            local cave=$((RANDOM % num_caves + 1))
            [[ " ${occupied[*]} " =~ " ${cave} " ]] && continue
            puzzle_caves+=("$cave"); occupied+=("$cave"); break
        done
    done
}

# Correct adjacency: check from an arbitrary cave, not always player_cave.
is_adjacent_from() {
    local from=$1 target=$2
    local connections=${cave_connections[$from]}
    IFS=',' read -ra adj <<< "$connections"
    for cave in "${adj[@]}"; do
        [[ $cave -eq $target ]] && return 0
    done
    return 1
}

get_adjacent() {
    echo "${cave_connections[$1]}" | tr ',' ' '
}

display_location() {
    clear
    echo "════════════════════════════════════════════════════════════"
    echo "                  HUNT THE WUMPUS"
    echo "════════════════════════════════════════════════════════════"
    echo
    echo "You are in cave $player_cave"
    echo "Tunnels lead to caves: $(get_adjacent "$player_cave")"
    echo

    local warnings=()

    for adj in $(get_adjacent "$player_cave"); do
        [[ $adj -eq $wumpus_cave ]] && warnings+=("You smell something terrible!")

        for pit in "${pit_caves[@]}"; do
            [[ $adj -eq $pit ]] && { warnings+=("You feel a draught of wind"); break; }
        done

        for bat in "${bat_caves[@]}"; do
            [[ $adj -eq $bat ]] && { warnings+=("You hear the flutter of wings"); break; }
        done

        for riddle in "${riddle_caves[@]}"; do
            if [[ $adj -eq $riddle ]] && [[ ! " ${solved_riddles[*]} " =~ " ${riddle} " ]]; then
                warnings+=("You hear a voice echo: 'Answer my riddle...'")
                break
            fi
        done

        for puzzle in "${puzzle_caves[@]}"; do
            if [[ $adj -eq $puzzle ]] && [[ ! " ${solved_puzzles[*]} " =~ " ${puzzle} " ]]; then
                warnings+=("You notice strange markings on the wall")
                break
            fi
        done
    done

    if [[ ${#warnings[@]} -gt 0 ]]; then
        printf '%s\n' "${warnings[@]}" | sort -u
        echo
    fi

    echo "────────────────────────────────────────────────────────────"
    echo "Arrows: $arrows_left | Moves: $moves | Score: $score"
    echo "────────────────────────────────────────────────────────────"
    echo
    echo "[M]ove, [S]hoot, [Q]uit?"
}

handle_riddle() {
    local cave=$1
    local riddle_num=$((RANDOM % 5 + 1))

    clear
    echo "════════════════════════════════════════════════════════════"
    echo "              RIDDLE GUARDIAN BLOCKS YOUR PATH"
    echo "════════════════════════════════════════════════════════════"
    echo
    echo "${riddles[$riddle_num]}"
    echo
    echo -n "Your answer: "

    stty echo icanon
    read -r answer
    stty -echo -icanon time 0 min 0

    answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')

    if [[ "$answer" == "${riddle_answers[$riddle_num]}" ]]; then
        ((score += 500))
        ((arrows_left++))
        solved_riddles+=("$cave")
        echo
        echo "Correct. Have an arrow. Hmmm Maye try not to waste it."
    else
        ((score -= 100))
        echo
        echo "Wrong. The answer was: ${riddle_answers[$riddle_num]}"
        echo "The guardian laughs. You lose points. Sucks to be you."
    fi

    echo
    echo "Press any key to continue..."
    read -n1 -s
}

handle_puzzle() {
    local cave=$1
    local puzzle_num=$((RANDOM % 4 + 1))

    IFS='|' read -r question hint <<< "${puzzles[$puzzle_num]}"

    clear
    echo "════════════════════════════════════════════════════════════"
    echo "                    LOGIC PUZZLE CHAMBER"
    echo "════════════════════════════════════════════════════════════"
    echo
    echo "$question"
    echo
    echo "Hint: $hint"
    echo
    echo -n "Your answer: "

    stty echo icanon
    read -r answer
    stty -echo -icanon time 0 min 0

    answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')

    if [[ "$answer" == *"${puzzle_answers[$puzzle_num]}"* ]]; then
        ((score += 750))
        ((arrows_left += 2))
        solved_puzzles+=("$cave")
        echo
        echo "Solved. The cave grudgingly respects you."
    else
        ((score -= 150))
        echo
        echo "Not quite. Maybe think harder next time. Or don't - (Pretend to be middle management). You'll die either way."
    fi

    echo
    echo "Press any key to continue..."
    read -n1 -s
}

move_player() {
    echo -n "Which cave? "
    stty echo icanon
    read -r target_cave
    stty -echo -icanon time 0 min 0

    [[ "$target_cave" =~ ^[0-9]+$ ]] || { echo "Invalid cave number"; sleep 1; return; }

    is_adjacent_from "$player_cave" "$target_cave" || { echo "You can't go there from here!"; sleep 1; return; }

    player_cave=$target_cave
    ((moves++))
    ((score -= 5))

    if [[ $player_cave -eq $wumpus_cave ]]; then
        game_over=1
        death_message="${death_messages[$((RANDOM % ${#death_messages[@]}))]}"
        clear
        echo "You stumble into the Wumpus's lair."
        echo "It eats you. Efficiently. Nom Nom Nom"
        echo
        echo "$death_message"
        echo
        echo "GAME OVER"
        return
    fi

    for pit in "${pit_caves[@]}"; do
        if [[ $player_cave -eq $pit ]]; then
            game_over=1
            death_message="${death_messages[$((RANDOM % ${#death_messages[@]}))]}"
            clear
            echo "You fall into a pit."
            echo
            echo "$death_message"
            echo
            echo "GAME OVER"
            return
        fi
    done

    for bat in "${bat_caves[@]}"; do
        if [[ $player_cave -eq $bat ]]; then
            echo
            echo "The Bats grab you. Because of course they do."
            sleep 1
            player_cave=$((RANDOM % num_caves + 1))
            echo "They drop you in cave $player_cave."
            ((score -= 50))
            sleep 2

            # If they drop you into instant death, so be it. That's bats.
            if [[ $player_cave -eq $wumpus_cave ]]; then
                game_over=1
                death_message="${death_messages[$((RANDOM % ${#death_messages[@]}))]}"
                echo "........ Riiggghhhtttt into the Wumpus's jaws."
                echo
                echo "$death_message"
                return
            fi
            for pit in "${pit_caves[@]}"; do
                if [[ $player_cave -eq $pit ]]; then
                    game_over=1
                    death_message="${death_messages[$((RANDOM % ${#death_messages[@]}))]}"
                    echo "...and into a pit."
                    echo
                    echo "$death_message"
                    return
                fi
            done
            return
        fi
    done

    for riddle in "${riddle_caves[@]}"; do
        if [[ $player_cave -eq $riddle ]] && [[ ! " ${solved_riddles[*]} " =~ " ${riddle} " ]]; then
            handle_riddle "$riddle"
            return
        fi
    done

    for puzzle in "${puzzle_caves[@]}"; do
        if [[ $player_cave -eq $puzzle ]] && [[ ! " ${solved_puzzles[*]} " =~ " ${puzzle} " ]]; then
            handle_puzzle "$puzzle"
            return
        fi
    done
}

shoot_arrow() {
    [[ $arrows_left -gt 0 ]] || { echo "You're out of arrows!"; sleep 1; return; }

    echo -n "Shoot through how many caves (1-5)? "
    stty echo icanon
    read -r num_caves_shoot
    stty -echo -icanon time 0 min 0

    [[ "$num_caves_shoot" =~ ^[1-5]$ ]] || { echo "Must be between 1 and 5"; sleep 1; return; }

    local path=()
    for ((i=1; i<=num_caves_shoot; i++)); do
        echo -n "Cave #$i? "
        stty echo icanon
        read -r cave_num
        stty -echo -icanon time 0 min 0
        [[ "$cave_num" =~ ^[0-9]+$ ]] || cave_num=0
        path+=("$cave_num")
    done

    ((arrows_left--))
    ((score -= 10))

    local current=$player_cave
    local hit_wumpus=0

    for target in "${path[@]}"; do
        if is_adjacent_from "$current" "$target"; then
            current=$target
        else
            echo
            echo "Arrows aren't that crooked. It ricochets randomly..."
            sleep 1
            local adj=($(get_adjacent "$current"))
            current=${adj[$((RANDOM % 3))]}
        fi

        [[ $current -eq $wumpus_cave ]] && { hit_wumpus=1; break; }
    done

    if [[ $hit_wumpus -eq 1 ]]; then
        game_over=1
        clear
        echo "════════════════════════════════════════════════════════════"
        echo "*** YOU'VE SLAIN THE WUMPUS ***"
        echo
        ((score += 1000))
        echo "Victory. Final Score: $score"
        echo "════════════════════════════════════════════════════════════"
        return
    fi

    echo
    echo "Miss. Your arrow becomes someone else's problem."

    # 75% chance the Wumpus moves
    if [[ $((RANDOM % 4)) -ne 0 ]]; then
        wumpus_awake=1
        local wumpus_adj=($(get_adjacent "$wumpus_cave"))
        local new_cave=${wumpus_adj[$((RANDOM % 3))]}

        if [[ $new_cave -eq $player_cave ]]; then
            game_over=1
            death_message="${death_messages[$((RANDOM % ${#death_messages[@]}))]}"
            echo "The Wumpus finds you.  (You suck at hide and seek)"
            echo
            echo "$death_message"
            echo
            echo "GAME OVER"
            sleep 2
            return
        fi

        wumpus_cave=$new_cave
        echo "You hear something large moving through the caves..."
    fi

    sleep 2
}

# Main
init_scores
init_riddles
init_puzzles
load_death_messages
show_high_scores

generate_caves

# Pick a start cave first so hazard placement doesn't spawn on you.
player_cave=$((RANDOM % num_caves + 1))
place_hazards

while [[ $game_over -eq 0 ]]; do
    display_location

    read -s -n1 action
    action=$(echo "$action" | tr '[:upper:]' '[:lower:]')

    case "$action" in
        m) move_player ;;
        s) shoot_arrow ;;
        q) game_over=1 ;;
    esac
done

# Clamp score. Negative scores aren't "hardcore", they're just petty.
(( score < 0 )) && score=0

sleep 2

lowest_score=$(tail -1 "$SCORE_FILE" 2>/dev/null | awk '{print $2}')
lowest_score=${lowest_score:-0}

if [[ $score -gt $lowest_score ]] || [[ $(wc -l < "$SCORE_FILE") -lt 10 ]]; then
    clear
    echo "════════════════════════════════════════════════════════════"
    echo "                   NEW HIGH SCORE"
    echo "════════════════════════════════════════════════════════════"
    echo
    echo "Final Score: $score"
    echo
    echo -n "Enter your name (8 chars): "

    stty echo icanon
    read -r player_name
    stty -echo -icanon time 0 min 0

    player_name=${player_name:0:8}
    [[ -z "$player_name" ]] && player_name="Anonymous"
    save_high_score "$player_name" "$score"
fi

sleep 1
show_high_scores
