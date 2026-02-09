# Docker Setup

This runs *Hunt the Wumpus* as a forgotten telnet service.
Yes, telnet (try googling it if your that young.!!!). That’s the point.

It’s meant to feel like something you weren’t supposed to find. Thatwas part of the funn.

---

## Build

From the project root:

```bash
docker build -t wumpus-server .
````

---

## Run

```bash
docker run -d -p 2323:2323 --name archive-service wumpus-server
```

Container name is deliberately boring.
Change it if you like, but resist the urge to be clever.

---------

## Connect

```bash
telnet localhost 2323
```

Login credentials:

```
user: gameuser
pass: games
```

Yes, the password is terrible.
No, that’s not an accident.

----

## Play

Once logged in:

```bash
/usr/local/games/wumpus
```

That’s it. No menu. No splash screen. No guidance.
If you found it, you’re probably the sort of person who can work it out.

-------

## Camouflage (Optional)

If you want it to blend in a bit better:

```bash
# Looks like MySQL
docker run -d -p 3306:2323 --name archive-service wumpus-server

# Looks like PostgreSQL
docker run -d -p 5432:2323 --name archive-service wumpus-server

# Looks like Redis
docker run -d -p 6379:2323 --name archive-service wumpus-server
```

Rename the container to something suitably dull:

```bash
archive-service
backup-daemon
log-rotator
metrics-cache
```

The goal is *forgettable*, not hidden.

--------

## Persistence

High scores live in `/tmp/.wumpus_scores` inside the container.

By default:

* Scores persist while the container runs
* Scores vanish when the container is removed

If you want them to survive restarts:

```bash
docker run -d -p 2323:2323 \
  -v wumpus-scores:/tmp \
  --name archive-service \
  wumpus-server
```

Whether high scores *should* be permanent is a philosophical question.
Docker doesn’t care.

-----

## Security (Read This, Then Ignore It Responsibly)

* Telnet is unencrypted
* Credentials are weak
* Anyone on the network with some smarts can read them

Do **not** expose this to the public internet unless:

* You understand the consequences
* You enjoy explaining things later

Local use or firewalled environments only.

------

## Troubleshooting

**Connection refused**

```bash
docker ps
netstat -tlnp | grep 2323
```

**Login incorrect**

* Username: `gameuser`
* Password: `games`
* All lowercase

**Game won’t start**

```bash
docker exec -it archive-service ls -l /usr/local/games/
```

**Terminal looks broken**

* UTF-8 encoding
* A terminal emulator that isn’t terrible
* WSL if you’re on Windows

------

## Why Telnet?

Because SSH would require keys, setup, and some good decisions.

This is about stumbling across something and thinking:

> “Why is this here?”

Telnet delivers that feeling perfectly.

--------

## Why Alpine?

Small. Fast. Has `telnetd`.
Anything bigger would be showing off.
