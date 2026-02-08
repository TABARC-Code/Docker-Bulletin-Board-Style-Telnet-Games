# Worm

A classic ASCII snake game, recreated from memory of those late-night sessions
telnetting into forgotten servers.

This is not a product.
It doesn’t phone home.
It doesn’t install anything.
It doesn’t care about your feelings.

It’s just a game that lives where games used to live.

## What This Is

- A terminal-based snake game written in Bash
- Designed to be discovered, not advertised - deliberate as you used to find these style games hidden in servers 
- Works locally or inside a deliberately boring Docker container
- Includes a telnet wrapper for the full “forgotten server” experience. We found them exploring or from Bulleten Boards

## Requirements (Local)

- Bash 4+
- A terminal that supports UTF-8 and box-drawing characters
- `tput`, `stty`, basic Unix tools

If your system doesn’t have those, that’s on you.

## Run Locally

```bash
chmod +x worm.sh
./worm.sh
 
------

## Controls

W / ↑ — Up

A / ← — Left

S / ↓ — Down

D / → — Right

Q — Quit

Eat *, grow longer, don’t hit walls or yourself.
Every food item is worth 10 points.

### High Scores

Scores are stored in:

/tmp/.worm_scores

## This means:

Scores persist while the machine/container is running

Scores disappear on reboot or container removal

Multiple users share the same leaderboard

If you want persistence, you can override this with an environment variable.

Docker (Optional, but Fun)

There’s a Dockerfile that sets up a telnet service exposing the game like a
forgotten maintenance box.

## Build it:

docker build -t worm-server .

## Run it:

docker run -d -p 2323:2323 --name backup-service worm-server

## Connect:

telnet localhost 2323

## Login:

user: gameuser
pass: games

## Then run:

/usr/local/games/worm
Why Telnet?

Because that’s how this stuff actually lived.
SSH is better. That’s not the point.

# Security

This is intentionally insecure.

Don't expose it to the public internet. I should not have to say ths but hey.
Do not run it on anything you care about.
Don't pretend this is a good idea in production.

Run it locally, on a LAN, or inside a lab where 'whimsy' is allowed. Or where you can leave it and have fun.
