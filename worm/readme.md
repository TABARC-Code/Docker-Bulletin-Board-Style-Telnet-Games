# Worm

<p align="center">
  <img src=".branding/tabarc-icon.svg" width="180" alt="TABARC-Code icon">
</p>

A small ASCII snake game for a terminal, or for a Telnet session that looks as though it has been left running in a forgotten server cupboard. No frameworks, accounts or network calls from the game itself.

## Requirements

Bash 5 or later, a UTF-8 terminal, `stty`, `tput` and the usual Unix command-line utilities. The Bash 5 requirement is deliberate: the game uses `EPOCHREALTIME` to keep movement independent of input.

From the Worm directory:

```sh
bash worm.sh
```

## Controls

| Key | Action |
| --- | --- |
| W or Up arrow | Move up |
| A or Left arrow | Move left |
| S or Down arrow | Move down |
| D or Right arrow | Move right |
| Q | Quit immediately |

Eat `*` to grow and earn ten points. Hitting a wall or your own body ends the game. Moving into the square just vacated by the tail is legal. You cannot reverse directly into yourself.

The snake advances once every 120 ms. Key presses update one pending turn; they never advance the clock. Repeated keys won't speed it up, and a backlog of missed frames is bounded. After a long terminal pause, the game resumes without trying to play every missed second.

Food appears only on unoccupied squares. When you fill the board, the game records a win rather than searching for a non-existent empty square. I prefer a victory screen to an infinite loop.

## High scores

The shared leaderboard defaults to `/tmp/.worm_scores`. Set the `SCORE_FILE` environment variable to use a different path. Scores stored inside a container are lost when that container is removed unless you mount a volume.

Quitting with Q does not prompt for a score. A normal game over may offer an eight-character name. An interrupted or disconnected session restores the terminal without leaving input echo disabled.

## Tests

From the repository root:

```sh
bash tests/worm-gameplay.sh
bash tests/worm-terminal.sh
make test
```

The gameplay checks cover fixed-step timing, catch-up, CSI/SS3 arrows, reversals, EOF, wall and self collisions, legal tail movement, growth, scoring and a full board. The pseudo-terminal test checks clean quitting and restoration of `stty` settings. It needs util-linux `script` and `timeout`.

## Docker and Telnet

From the repository root:

```sh
make build-worm
make run-worm
telnet 127.0.0.1 2323
```

Log in as `gameuser` with password `games`, then run `/usr/local/games/worm`. The image uses Alpine 3.24.3. The default host binding remains `127.0.0.1`; don't publish this Telnet service to the internet. Credentials and game traffic are unencrypted.

Use `make stop-worm` to remove the running container. For a trusted LAN, specify the Docker host's actual LAN IP using `BIND_ADDR` and restrict access with a firewall. See the repository [security notes](../SECURITY.md).
