# Changes

## v1.0.0

- Fixed invalid `local` declarations in the Robots main loop so movement and rollback keep their coordinates.
- Fixed robot pile-ups: every colliding robot is removed, with one debris heap per square and correct scoring.
- Added Bash regression checks and a versioned project baseline.

Note: The other games retain their existing individual versions. This number tracks the combined Docker collection.
