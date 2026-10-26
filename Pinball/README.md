# Pinball

A small ASCII pinball table served over Telnet. It is deliberately a terminal game, not a modern arcade simulator wearing a text-mode disguise.

## Playing

Connect to the Pinball container on port `2325` (the default Docker binding is `127.0.0.1`). Log in with the collection's local game account and run `/usr/local/games/pinball`. A terminal at least 42 columns wide and 29 rows high is recommended.

Press any key to leave the high-score screen. **Space** launches a ball, **A** operates the left flipper, **D** the right, and **Q** quits. There are three balls. Bumpers build a combo up to five times; targets score separately. Flippers are active briefly after a press, so timing still matters.

## What changed

The chute now sends the ball towards the upper-right bumper rather than straight into the drain. The simulation runs at a fixed 12.5 steps per second and checks intermediate positions for collisions. Input frequency no longer changes the rate of play. A bounded catch-up prevents a slow terminal from triggering an unlimited backlog of physics steps.

I also separated the table logic from terminal drawing, which makes the trajectory and collision tests repeatable. The old loop mixed key reads, gravity and rendering. That was convenient until it wasn't.

## Checks

From the repository root:

```sh
bash tests/pinball-physics.sh
bash tests/pinball-terminal.sh
make test
```

The first check exercises the launch, bumper and target contacts, flipper saves, drains, fixed-step pacing, catch-up and quitting. The second opens a pseudo-terminal and checks the real start-and-quit path. `make test` also runs checks for the other games and Alpine image versions; its overall result depends on those separate components.

The Pinball Dockerfile currently uses Alpine 3.24.3. Keep the Telnet service on a trusted, firewalled network. It is not encrypted.
