# Docker-Bulletin-Board-Style-Telnet-Games
A collection of classic ASCII games such as Hunt the Wumpus, snake, robots, and pinball. Recreated from memory of those late-night sessions telnetting into forgotten servers. I was bored and this was a nice bit of nostalgia.


## The Idea
Back in the day, these games lived on servers. You'd be poking around, checking out /usr/local/games/, and there they were. No fanfare, no documentation, just there. This Docker setup recreates that.

## Collection release

Current release: **v1.0.0** (see `VERSION` and `CHANGELOG.md`). Individual game versions remain separate.

From the repository root, run `make test` for shell syntax and Robots regression checks, or `make build-all` to build the containers. `make version` prints the collection version.

**Network note:** the existing Telnet services use unencrypted logins and deliberately simple passwords. Keep deployments restricted to a trusted, firewalled network; do not publish these ports to the internet.
