# Changes

## v2.0.5

- Reworked Worm movement to run at a fixed 120 ms step, with bounded catch-up and a reset after backwards clock changes. Input frequency no longer controls snake speed.
- Added CSI and SS3 arrow-key parsing, a single pending turn per tick and checks against reversing into the body.
- Corrected food placement after growth. New food cannot appear beneath the head, and filling the board ends in a win rather than an endless placement loop.
- Fixed wall, body and vacating-tail collisions, with 10 points per food item. Repainting now touches only the changed cells.
- Restored the original terminal settings on normal exit, Ctrl-C, termination and hang-up; EOF and Q leave without prompting for a high score.
- Added deterministic Worm gameplay tests and a pseudo-terminal restoration check to make test and CI. Updated the Worm guide.

I separated keyboard reads from movement. Pressing keys faster should not make the snake faster, however determined the player might be.

The Bash gameplay and pseudo-terminal tests passed locally. Container builds and live Telnet sessions still require a Docker-capable runner or host for confirmation.

## v2.0.4

- Brought Hunt the Wumpus onto Alpine 3.24.3, matching the other three game containers.
- Corrected puzzle clues that previously gave away the solutions. The weighing puzzle now checks the three group sizes rather than accepting 'yes'.
- Normalised case and spacing in answers; rejected partial or padded-out guesses.
- Restored terminal state on exit, kept failure codes intact and handled disconnected sessions without repeatedly asking for input.
- Added deterministic Wumpus gameplay and hazard checks to the collection test target.
- Tidied the Wumpus playing instructions. The collection's Alpine migration is now reflected in the source and test configuration.

The hints were doing far too much of the thinking. That seems a poor arrangement for a puzzle game.

Docker image builds and live Telnet sessions still need successful CI or host-side confirmation.

## v2.0.3

- Rebalanced the Pinball launch: it now reaches a bumper and allows a timed flipper save.
- Added fixed-step physics with bounded catch-up and substep checks for fast bumper, target and flipper contacts.
- Separated key input from physics so repeated key presses do not accelerate the ball.
- Capped the combo multiplier at five, corrected flipper return direction and improved terminal cleanup.
- Added deterministic gameplay and pseudo-terminal quit checks, plus a dedicated Pinball CI job.
- Added Pinball playing notes and test instructions.

I wanted a pinball table, not a ball disposal chute. The launch now makes it into play.

The wider Alpine migration is still unfinished; the Wumpus image remains on its earlier base and the collection-wide image check is expected to fail until that is resolved.

## v2.0.2

- Updated the collection version marker and documentation.
- The Alpine migration remains in progress. This version number does not indicate a completed container test run.

## v1.8.2

- Repaired the 35-cave Wumpus map: tunnels now work both ways, with three four-exit caves.
- Updated ricochets and Wumpus movement to select from the actual neighbouring caves.
- Included the external death messages in the Wumpus image.
- Bound all four Telnet ports to localhost by default, with explicit LAN opt-in.
- Added map, asset and network regression checks; extended the CI test target.
- Clarified the Docker instructions and firewall guidance.

Note: the old map had a few tunnels that only worked in one direction. Odd behaviour for a tunnel, even here.

## v1.0.0

- Fixed invalid `local` declarations in the Robots main loop so movement and rollback keep their coordinates.
- Fixed robot pile-ups: every colliding robot is removed, with one debris heap per square and correct scoring.
- Added Bash regression checks and a versioned project baseline.

Note: The other games retain their existing individual versions. This number tracks the combined Docker collection.
