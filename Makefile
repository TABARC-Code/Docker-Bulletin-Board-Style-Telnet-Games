# Docker Bulletin Board Telnet Games
# Ports: worm=2323, robots=2324, pinball=2325, wumpus=2326

.PHONY: build-all build-worm build-robots build-pinball build-wumpus \
        run-all run-worm run-robots run-pinball run-wumpus \
        stop-all stop-worm stop-robots stop-pinball stop-wumpus \
        status connect-worm connect-robots connect-pinball connect-wumpus

# ── Build ──────────────────────────────────────────────────────────────────────

build-all: build-worm build-robots build-pinball build-wumpus

build-worm:
	docker build -t worm-server ./worm

build-robots:
	docker build -t robots-server ./Robot

build-pinball:
	docker build -t pinball-server ./Pinball

build-wumpus:
	docker build -t wumpus-server ./"Hunt the Wumpus"

# ── Run ───────────────────────────────────────────────────────────────────────

run-all: run-worm run-robots run-pinball run-wumpus

run-worm:
	docker run -d -p 2323:2323 --name backup-service worm-server

run-robots:
	docker run -d -p 2324:2323 --name log-rotator robots-server

run-pinball:
	docker run -d -p 2325:2323 --name cache-service pinball-server

run-wumpus:
	docker run -d -p 2326:2323 --name archive-service wumpus-server

# ── Stop ──────────────────────────────────────────────────────────────────────

stop-all: stop-worm stop-robots stop-pinball stop-wumpus

stop-worm:
	docker stop backup-service && docker rm backup-service

stop-robots:
	docker stop log-rotator && docker rm log-rotator

stop-pinball:
	docker stop cache-service && docker rm cache-service

stop-wumpus:
	docker stop archive-service && docker rm archive-service

# ── Connect ───────────────────────────────────────────────────────────────────

connect-worm:
	telnet localhost 2323

connect-robots:
	telnet localhost 2324

connect-pinball:
	telnet localhost 2325

connect-wumpus:
	telnet localhost 2326

# ── Status ────────────────────────────────────────────────────────────────────

status:
	@docker ps --filter name=backup-service \
	           --filter name=log-rotator \
	           --filter name=cache-service \
	           --filter name=archive-service \
	           --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
