# Security

This project is intentionally insecure. That's the point.

It recreates the experience of stumbling across old terminal games on a forgotten server. Part of that experience is terrible credentials, plain-text protocols, and the general vibe of something that nobody has thought about since 1994.

So yes — telnet, weak passwords, world-writable `/tmp`. On purpose.

---

## What this means in practice

| Thing | Status | Why |
|-------|--------|-----|
| Telnet (unencrypted) | Intentional | Historically accurate. SSH kills the atmosphere. |
| Hardcoded credentials (`gameuser:games`) | Intentional | Part of the discovery aesthetic. |
| No rate limiting | Known | It's a game server, not a bank. |
| Scores stored in `/tmp` | Known | Ephemeral by design. Persistence is optional. |

---

## Where this is safe to run

- Your laptop, locally
- A home lab or private LAN
- A firewalled internal network where everyone already knows each other
- A CTF or retro computing event
- Anywhere you'd happily run Doom on a shared machine

## Where this is NOT safe to run

- Exposed to the public internet
- On production infrastructure
- Anywhere with compliance requirements
- Anywhere your employer would find out about

---

## Reporting issues

If you find a genuine security issue beyond the intentional ones listed above, raise it as a GitHub issue. There's no responsible disclosure process here — this is a toy, not critical infrastructure.

If someone tells you to "patch the telnet", they've missed the point entirely.

---

## Firewall recommendation

If you want to run this anywhere semi-public, restrict access at the network level:

```bash
# Allow only your local subnet
ufw allow from 192.168.1.0/24 to any port 2323
ufw allow from 192.168.1.0/24 to any port 2324
ufw allow from 192.168.1.0/24 to any port 2325
ufw allow from 192.168.1.0/24 to any port 2326
```

That's the security story. It's short because it needs to be.
