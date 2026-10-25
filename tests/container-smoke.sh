#!/usr/bin/env bash
# Run with a Docker daemon after make build-all.
# This checks the actual runtime: the login binary, Telnet daemon and scripts.
set -euo pipefail
cd "$(dirname "$0")/.."

check_image() {
    local image=$1 game=$2
    docker run --rm --entrypoint /bin/sh "$image" -ec '
        test -x /usr/sbin/telnetd
        test -x /bin/login
        test -x /bin/bash
        test -s /etc/motd
        test -x "/usr/local/games/$1"
        /bin/bash -n "/usr/local/games/$1"
        TERM=xterm-256color tput clear >/dev/null
    ' check "$game"
    printf "Container check passed: %s\n" "$game"
}

check_image worm-server worm
check_image robots-server robots
check_image pinball-server pinball
check_image wumpus-server wumpus
docker run --rm --entrypoint /bin/sh wumpus-server -ec     'test -s /usr/local/games/death_messages.txt'
echo "All container checks passed."
