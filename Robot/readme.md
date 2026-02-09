
<p align="center">
  <img src=".branding/tabarc-icon.svg" width="180" alt="TABARC-Code Icon">
</p>
# Robots

Strategic ASCII game where you dodge robots and make them crash into each other.
A thinking person’s arcade game.

## The idea

Robots move one step closer to you each turn (both axes).
You win by not being where they’re going to be.

## Controls
Y K U
H-@-L
B J N


- Y K U H L B J N: move (8 directions)
- W: wait
- T: teleport (limited)
- Q: quit

Legend:
- `@` you
- `+` robot
- `*` junk (crashed robots)
- `#` explosion flash
- `X` you, but worse

## Run

```bash
chmod +x robots.sh
./robots.sh

High scores default to /tmp/.robots_scores (override with SCORE_FILE if you want permanence).
High scores default to /tmp/.robots_scores (override with SCORE_FILE if you want permanence).


## `DOCKER.md`

```markdown
# Docker setup for Robots

Hidden server game theatre via telnet. Don’t expose it to the internet unless you enjoy incident response.

## Quick start

```bash
docker build -t robots-server .
docker run -d -p 2323:2323 --name log-rotator robots-server
telnet localhost 2323

### Login:

user: gameuser

pass: games

## Run:

/usr/local/games/robots

# Camouflage

### Ports that look “legitimate”:

docker run -d -p 3306:2323 robots-server   # MySQL
docker run -d -p 5432:2323 robots-server   # PostgreSQL
docker run -d -p 6379:2323 robots-server   # Redis

# Persistence

## By default scores are ephemeral (/tmp). To persist:

docker run -d -p 2323:2323 \
  -v robots-scores:/tmp \
  --name robots-server \
  robots-server

  docker run -d -p 2323:2323 \
  -v robots-scores:/tmp \
  --name robots-server \
  robots-server
