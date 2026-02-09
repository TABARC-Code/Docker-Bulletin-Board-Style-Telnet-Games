
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

## Run
docker run -d -p 2323:2323 --name cache-service pinball-server

## Connect
telnet localhost 2323

## Credentials:
user: gameuser
pass: games

###v Then run:
/usr/local/games/pinball

## docker-compose
docker-compose up -d
telnet localhost 2323

## Stealth Options
### Port Camouflage
docker run -d -p 3306:2323 pinball-server   # looks like MySQL
docker run -d -p 5432:2323 pinball-server   # looks like PostgreSQL
docker run -d -p 6379:2323 pinball-server   # looks like Redis

## Boring Container Names
cache-service
metrics-exporter
backup-daemon

### Nobody checks these unless something is on fire.

## Persistence

#### Scores live in /tmp/.pinball_scores.

#### If you want persistence:
docker run -d -p 2323:2323 \
  -v pinball-scores:/tmp \
  --name pinball-server \
  pinball-server

  If you don’t, embrace impermanence.

## Security

* Telnet is unencrypted
* Password is weak
* Anyone on the network can sniff credentials

Do not expose this to the public internet. (sseriusly!)
Run it locally or on a private network where bad ideas are allowed.
