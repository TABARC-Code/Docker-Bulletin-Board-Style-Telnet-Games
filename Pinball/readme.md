# Pinball

<p align="center">
  <img src=".branding/tabarc-icon.svg" width="180" alt="TABARC-Code Icon">
</p>

ASCII pinball with physics, flippers, bumpers, and the satisfying sound of nothing,
because terminals don’t make noise.

This is not a remake of anything specific.
It’s a reconstruction from memory of weird little games that lived on Unix boxes
in the late 90s and early 2000s.

It exists because someone once thought “yes, pinball, but text-only” and they were
absolutely correct.

## What This Is

- Terminal-based ASCII pinball written in Bash
- Physics-driven ball movement (gravity, velocity, bouncing)
- Active flippers with timing windows
- Bumpers, targets, combos, and score multipliers
- High score table shared between users on the same machine
- Optional telnet wrapper for the full “forgotten server” experience

## Requirements (Local)

- Bash 4.0+
- A terminal that supports UTF-8
- `tput`, `stty`, and basic Unix utilities
- Reasonable hand–eye coordination

## Run Locally

```bash
chmod +x pinball.sh
./pinball.sh

No install step. No dependencies to fetch. It either runs or it doesn’t.

## Controls

A – Left flipper

D – Right flipper

SPACE – Launch ball

Q – Quit

Flippers stay active briefly after you press the key.
Timing matters. Mashing does not help. But it is fun.

# How to Play

Press SPACE to launch a ball

Use flippers to keep it in play

Hit bumpers (◉) to build combo multiplier

Hit all targets (▓) to score a bonus and reset them

Don’t drain the ball

Repeat until you run out of balls or patience

Scoring

Bumper hit: points × combo

Target hit: 250 × combo

All targets cleared: +1000

Flipper save: +10

Combos reset when you lose a ball.
A ball at high combo is worth more than a fresh one.

High Scores

## Scores are stored in:

/tmp/.pinball_scores

## This means:

Scores persist while the system/container is running

Scores are lost on reboot or container removal

Multiple users share the same table

You can override this with an environment variable if you care.

### Docker

There’s a Dockerfile that exposes the game via telnet, disguised as a boring service.

See DOCKER.md for details.
