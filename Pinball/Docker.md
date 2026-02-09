
-----

## `DOCKER.md`

```markdown
# Docker Setup for Pinball

Hidden ASCII pinball via telnet.
Because sometimes you just want to log into something and waste time quietly.

## What This Does

- Runs a telnet server inside a small Alpine container
- Presents itself as a boring cache or maintenance service
- Hides the game in `/usr/local/games/`
- Uses deliberately bad credentials (on purpose)

This is about discovery, not security. Bit of nostalga fun

## Build

```bash
docker build -t pinball-server .
