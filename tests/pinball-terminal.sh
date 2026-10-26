#!/usr/bin/env bash
# Exercise the real terminal entry/exit path as well as the pure game logic.
set -euo pipefail
cd "$(dirname "$0")/.."
command -v script >/dev/null || { echo 'PTY test requires util-linux script' >&2; exit 1; }
command -v timeout >/dev/null || { echo 'PTY test requires timeout' >&2; exit 1; }
score_dir=$(mktemp -d)
trap 'rm -rf "$score_dir"' EXIT
# First key dismisses the scores, second quits without waiting for a score name.
if ! printf 'xq' | TERM=xterm-256color SCORE_FILE="$score_dir/scores" \
        timeout 8 script -q -e -c 'before=$(stty -g); bash Pinball/pinball.sh; test "$(stty -g)" = "$before"' /dev/null >/dev/null 2>&1; then
    echo 'Pinball did not quit cleanly under a pseudo-terminal' >&2
    exit 1
fi
[[ -s "$score_dir/scores" ]] || { echo 'Score file was not initialised' >&2; exit 1; }
echo 'Pinball terminal quit check passed.'
