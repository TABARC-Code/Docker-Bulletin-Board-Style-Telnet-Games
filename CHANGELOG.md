# Changes

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
