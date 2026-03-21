
<p align="center">
  <img src=".branding/tabarc-icon.svg" width="180" alt="TABARC-Code Icon">
</p>

# Robots

Strategic ASCII game where you dodge robots and make them crash into each other.
A thinking person's arcade game.

## The Idea

Robots move one step closer to you each turn (both axes).
You win by not being where they're going to be.

## Controls

```
Y K U
H-@-L
B J N
```

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
chmod +x Robots.sh
./Robots.sh
```

High scores default to `/tmp/.robots_scores` (override with `SCORE_FILE` if you want permanence).

---

## Docker Setup

Hidden server game via telnet. Don't expose it to the internet unless you enjoy incident response.

### Quick Start

```bash
docker build -t robots-server .
docker run -d -p 2323:2323 --name log-rotator robots-server
telnet localhost 2323
```

### Login

```
user: gameuser
pass: games
```

### Run the Game

```bash
/usr/local/games/robots
```

### Camouflage

Ports that look "legitimate":

```bash
docker run -d -p 3306:2323 robots-server   # MySQL
docker run -d -p 5432:2323 robots-server   # PostgreSQL
docker run -d -p 6379:2323 robots-server   # Redis
```

### Persistence

By default scores are ephemeral (`/tmp`). To persist:

```bash
docker run -d -p 2323:2323 \
  -v robots-scores:/tmp \
  --name robots-server \
  robots-server
```
