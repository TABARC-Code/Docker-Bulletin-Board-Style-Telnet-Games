#!/usr/bin/env bash
# Check normal exit and terminal restoration under a real pseudo-terminal.
set -euo pipefail
cd "$(dirname "$0")/.."
command -v script >/dev/null || { echo 'util-linux script is required' >&2; exit 1; }
command -v timeout >/dev/null || { echo 'timeout is required' >&2; exit 1; }
score_dir=$(mktemp -d)
trap 'rm -rf "$score_dir"' EXIT
if ! printf 'xq' | TERM=xterm-256color SCORE_FILE="$score_dir/scores" \
        timeout 8 script -q -e -c 'before=$(stty -g); bash worm/worm.sh; test "$(stty -g)" = "$before"' /dev/null >/dev/null 2>&1; then
    echo 'Worm did not quit cleanly or restore the terminal' >&2
    exit 1
fi
[[ -s "$score_dir/scores" ]] || { echo 'Worm did not initialise the score file' >&2; exit 1; }
# Check the exit trap preserves non-zero statuses, including SIGINT's 130.
for status in 17 129 130 143; do
    set +e
    TERM=xterm-256color bash -c '
        source <(sed -n "/^cleanup() {/,/^}/p" "$1")
        trap cleanup EXIT
        original_stty=""
        exit "$2"
    ' _ worm/worm.sh "$status" >/dev/null 2>&1
    actual=$?
    set -e
    [[ $actual -eq $status ]] || { echo "Worm lost exit status $status" >&2; exit 1; }
done
echo 'Worm terminal checks passed.'
