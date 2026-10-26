# Docker-Bulletin-Board-Style-Telnet-Games
A collection of classic ASCII games such as Hunt the Wumpus, snake, robots, and pinball. Recreated from memory of those late-night sessions telnetting into forgotten servers. I was bored and this was a nice bit of nostalgia.


## The Idea
Back in the day, these games lived on servers. You'd be poking around, checking out /usr/local/games/, and there they were. No fanfare, no documentation, just there. This Docker setup recreates that.

## Collection release

Current collection version: **v2.0.5** (see `VERSION` and `CHANGELOG.md`). This release repairs Worm movement, food spawning and terminal handling. The Alpine 3.24.3 and Pinball updates remain in place. Individual game versions remain separate.

From the repository root, run `make test` for Bash syntax, Worm and Pinball gameplay and terminal checks, Robots collisions, Wumpus cave-map, gameplay and asset checks, and deployment binding checks. Run `make build-all` to build the containers. `make version` prints the collection version.

## Worm gameplay

Worm now moves at a fixed 120 ms per square, rather than taking an extra step every time the keyboard is polled. WASD and both common arrow-key sequences work; turns are queued once per step and a direct reversal is rejected. Food is placed only after growth, the head cannot hide the next meal, and filling the board wins the game. The original terminal settings are restored on quit or interruption.

Run `bash tests/worm-gameplay.sh` and `bash tests/worm-terminal.sh` to check it independently. The terminal check requires util-linux `script` and `timeout`. Local play requires Bash 5 or later; see the [Worm guide](worm/readme.md).

## Pinball gameplay

The Pinball launch now reaches the upper table, with bumper contacts and a realistic opportunity to use the right flipper. The physics runs at 12.5 fixed steps per second with intermediate collision checks, rather than advancing every time the input loop happens to finish. A held or repeated key no longer speeds up the ball.

Use **Space** to launch, **A** and **D** for the flippers, and **Q** to quit. The combo multiplier tops out at five. Run `bash tests/pinball-physics.sh` and `bash tests/pinball-terminal.sh` to check Pinball independently; see [Pinball notes](Pinball/README.md) for details.

## Wumpus gameplay

Wumpus puzzles now give clues instead of solutions. Answers ignore case and extra spaces, but partial matches no longer count. Terminal settings are restored on exit and abandoned connections close cleanly. Use `bash tests/wumpus-gameplay.sh` for the focused checks and see [Wumpus instructions](Hunt%20the%20Wumpus/README.md).

## Alpine maintenance

Worm, Robots, Pinball and Hunt the Wumpus now all use the pinned Alpine `3.24.3` base. The source-image check is part of `make test`; `make test-containers` builds and inspects all four images on a machine with Docker. Actual container builds and live Telnet connections still need runtime confirmation.

## Quick start

You'll need Docker, GNU Make and a Telnet client. From the repository root:

```bash
make test
make build-all
make run-all
make status
telnet 127.0.0.1 2323
```

The other ports are Robots `2324`, Pinball `2325` and Hunt the Wumpus `2326`. Log in with `gameuser` / `games`, then run `/usr/local/games/worm`, `/usr/local/games/robots`, `/usr/local/games/pinball` or `/usr/local/games/wumpus` in the corresponding container. Use `make stop-all` to remove the running containers.

Each game also has a `docker-compose.yml` in its directory. For example:

```bash
docker compose -f Robot/docker-compose.yml up -d --build
telnet 127.0.0.1 2324
```

## LAN access (optional)

The default is `127.0.0.1`: connections from other machines are **not** accepted. For a trusted private network, explicitly select the Docker host's LAN IP:

```bash
make run-all BIND_ADDR=192.168.1.10
# Or, for a single Compose game:
BIND_ADDR=192.168.1.10 docker compose -f Robot/docker-compose.yml up -d --build
```

Use your actual host IP, not the example. Permit only trusted clients through a firewall and check your router has no port forwarding for these services. Telnet sends credentials and traffic unencrypted; the vintage experience is not a security feature. See `SECURITY.md`.

**Network note:** the existing Telnet services use unencrypted logins and deliberately simple passwords. Keep deployments restricted to a trusted, firewalled network; do not publish these ports to the internet.
