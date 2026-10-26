<p align="center">
  <img src=".branding/tabarc-icon.svg" width="180" alt="TABARC-Code icon">
</p>

# Hunt the Wumpus: Extended Edition

Thirty-five caves, one Wumpus, three pits and enough bats to spoil a perfectly sensible expedition. Riddle guardians and logic puzzles live among the hazards.

Based on Gregory Yob's 1973 game, with additional chambers and a few deliberate complications.

## Play locally

From this directory:

```sh
chmod +x wumpus.sh
./wumpus.sh
```

Bash, `stty`, `tput` and a terminal supporting basic UTF-8 characters are required.

## Controls

- **M:** move to a connected cave by entering its number
- **S:** shoot along a path of one to five cave numbers
- **Q:** quit

A bad arrow route can ricochet through another tunnel. The Wumpus may move after a missed shot.

## What the warnings mean

| Warning | Nearby trouble |
| --- | --- |
| An unpleasant smell | The Wumpus |
| A draught | A pit |
| Fluttering wings | Bats |
| A distant voice | An unsolved riddle |
| Strange markings | An unsolved puzzle |

## Riddles and puzzles

Answers ignore capital letters and extra spacing, but must actually match. Adding the answer somewhere in a paragraph no longer passes. The logic chambers give a clue, not the solution. Oddly enough, solving something is more satisfying that way.

## Scores and tests

High scores default to `/tmp/.wumpus_scores`. Set `SCORE_FILE` to use another path; use a Docker volume for persistence.

From the repository root:

```sh
bash tests/wumpus-map.sh
bash tests/wumpus-gameplay.sh
bash tests/alpine-base.sh
```

The map tests verify reciprocal tunnels, reachability and the installed death-message asset. Gameplay tests check answers, hazards and terminal exit behaviour.

## Docker

The container uses the collection's pinned Alpine 3.24.3 base. Use `make build-wumpus` and `make run-wumpus` from the repository root, then connect to `127.0.0.1:2326`.

Telnet is unencrypted and the game login is deliberately weak. Leave it on loopback unless you have explicitly restricted a trusted LAN. See [Docker setup](docker.md) and [security guidance](../SECURITY.md).
