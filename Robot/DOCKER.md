## `DOCKER.md`

```markdown
# Docker setup for Robots

Hidden server game theatre via telnet. Don’t expose it to the internet unless you enjoy incident response.

## Quick start

```bash
docker build -t robots-server .
docker run -d -p 2323:2323 --name log-rotator robots-server
telnet localhost 2323

## Login:

user: gameuser

pass: games

## Run:

/usr/local/games/robots

## Camouflage

### Ports that look “legitimate”:

docker run -d -p 3306:2323 robots-server   # MySQL
docker run -d -p 5432:2323 robots-server   # PostgreSQL
docker run -d -p 6379:2323 robots-server   # Redis

## Persistence

By default scores are ephemeral (/tmp). To persist:

docker run -d -p 2323:2323 \
  -v robots-scores:/tmp \
  --name robots-server \
  robots-server
