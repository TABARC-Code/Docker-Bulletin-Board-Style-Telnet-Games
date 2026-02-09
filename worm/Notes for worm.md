Right, here’s your **human, slightly chaotic, UK-flavoured notes version** in proper Markdown, but still structured enough to actually use.

-----------

# 🐛 WORM TELNET SERVER THING

Old-school terminal game hiding inside what looks like a dull service.
It Looks like infrastructure. Is actually snake. Small Priorities.

------

## What this actually does

* Runs a **telnet server** (yes, telnet, like it’s 1995 and nobody’s heard of TLS)
* One user account

  * **Username:** `gameuser`
  * **Password:** `games` (spectacularly bad, artistically correct)
* MOTD pretends to be a boring backup service
* The game lives at:

```
/usr/local/games/worm
```

No SSH.
No HTTPS.
No modern security theatre.
Just telnet and vibes.

-------

## Setup

### Build the Docker image

```bash
docker build -t worm-server .
```

### Run it

```bash
docker run -d -p 2323:2323 --name worm-server worm-server
```

### Connect

```bash
telnet localhost 2323
```

Login:

```
Username: gameuser
Password: games
```

### Start the game

```bash
/usr/local/games/worm
```

---

# Making it look “forgotten”, not hidden

The goal is **discovery**, not secrecy. Like tripping over an old arcade machine in a server rack.

---

## Use a port that looks legitimate

Make it resemble something serious:

```bash
docker run -d -p 3306:2323 worm-server   # looks like MySQL
docker run -d -p 5432:2323 worm-server   # looks like PostgreSQL
docker run -d -p 8081:2323 worm-server   # looks like alt HTTP
```

--------

## Rename the container to something dull

```bash
docker run -d -p 2323:2323 --name backup-service worm-server
docker run -d -p 2323:2323 --name log-rotator worm-server
docker run -d -p 2323:2323 --name cache-warmer worm-server
```

Nobody investigates “log-rotator”. Well some pedantic coder will but to know what i mean.

------

## Leave breadcrumbs (important)

Subtle clues > obvious signs.

### Shell history

```bash
echo "# legacy telnet still running on :2323" >> ~/.bash_history
```

### Random config comment

```bash
# TODO: remove deprecated telnet service on port 2323
# - gameuser:games for testing
# - scheduled for next maintenance window
```

### README fragment somewhere

```markdown
### Deprecated Services

The following services are scheduled for decommission:

- Legacy backup telnet (port 2323)
- DO NOT USE
```

Key idea: **looks forgotten**, not secret.

-------

# ⚠️ Security warning (seriously)

This is intentionally bad security.

**Do NOT:**

* Expose to the public internet
* Run on production infrastructure

**Do:**

* Keep it on local networks
* Use firewall rules
* Accept that passwords are sniffable in plain text

If deploying somewhere real:

* Restrict access via firewall
* Use a strong password (kills the joke, saves your job)
* Or just use SSH and abandon the bit

Or, better:

```bash
telnet localhost 2323
```

Like a sensible goblin.

-------

# Persistence

High scores stored in:

```
/tmp/.worm_scores
```

Meaning:

* Persist while container runs
* Gone when container is removed
* Shared between all players on that container (good chaos)

### Want persistent scores?

```bash
docker run -d -p 2323:2323 \
  -v worm-scores:/tmp \
  --name worm-server \
  worm-server
```

Now scores survive restarts.

Whether they *should* is a philosophical matter.

-------

# Customisation

## Change the MOTD

Edit `motd` before building:

```
===============================================================================
YOUR BORING SERVICE NAME HERE
===============================================================================
Everything is fine. Nothing to see here.

Oh, there might be some old stuff in /usr/local/games/ but it's broken.
Probably. Haven't checked in years.
===============================================================================
```

Subtlety wins.
“THERE ARE GAMES HERE” ruins everything. seriously i shuldd not have to say ths.

----

## Change credentials

In the Dockerfile:

```dockerfile
RUN adduser -D -s /bin/bash gameuser && \
    echo "gameuser:your_password_here" | chpasswd
```

But honestly, terrible passwords are part of the aesthetic.

--------

# Troubleshooting

### “Connection refused”

* Container running?

  ```bash
  docker ps
  ```
* Port mapped correctly? Check `-p`
* Port already in use?

  ```bash
  netstat -tlnp | grep 2323
  ```
----
---

### “Login incorrect”

* Username: `gameuser`
* Password: `games`
* Check user exists:

  ```bash
  docker exec -it worm-server cat /etc/passwd | grep gameuser
  ```

-------

### “Game won’t start”

```bash
docker exec -it worm-server ls -l /usr/local/games/
```

Check permissions. Probably fine. Probably.

-------

### Terminal looks weird

* Use UTF-8
* Needs box-drawing support
* Some terminal emulators are just cursed

-------

# Why telnet?

Because SSH adds friction and ruins the “stumbled into this at 2am” feeling.

Also historically accurate. This is archaeology, not nostalgia bait.

------

# The Game Itself – WORM

Classic ASCII snake.

Found on forgotten servers at unreasonable hours.

------

## Features

* Classic snake gameplay
* Proper Unicode box characters
* Persistent high scores (top 10)
* WASD or arrow keys
* No internet, no tracking, no nonsense

------

## Requirements

* Bash 4+
* A terminal that behaves
* `tput`, `stty`, basic Unix tools

If those are missing, your system is the problem.

-------

## Install (non-Docker)

```bash
git clone https://github.com/yourusername/worm.git
cd worm
chmod +x worm.sh
./worm.sh
```

No npm.
No pip.
No dependency theatre.

------

## How to play

* Run `./worm.sh`
* Move with WASD or arrows
* Eat `*`
* Don’t hit walls or yourself
* Worm moves automatically, you steer

Each food = **+10 points** + longer tail = increasing regret. yup th classic

------

## High scores

Stored in:

```
/tmp/.worm_scores
```

* Shared on a server
* Solo sadness locally
* Wiped on reboot

Yes, you could edit it. That would make you a coward.

------

## Controls

| Key   | Action |
| ----- | ------ |
| W / ↑ | Up     |
| A / ← | Left   |
| S / ↓ | Down   |
| D / → | Right  |
| Q     | Quit   |

-----

## Technical bits

* Uses `tput` for cursor movement
* `stty` for raw input
* POSIX shell
* ~12 FPS because that *feels right*, not because science

------

## Code quality

It’s Bash.

* Elegant? No.
* Works? Yes.
* Good enough? Absolutely.

------

## Final thought

Security says **no**.
Fun says **absolutely yes**.

Know which voice you’re listening to before deploying.
