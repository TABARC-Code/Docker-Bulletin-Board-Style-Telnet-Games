FROM alpine:3.19

LABEL org.opencontainers.image.title="worm" \
      org.opencontainers.image.description="Classic ASCII snake game served via telnet" \
      org.opencontainers.image.source="https://github.com/TABARC-Code/Docker-Bulletin-Board-Style-Telnet-Games"

RUN apk add --no-cache \
    bash \
    busybox-extras \
    ncurses \
    ncurses-terminfo

RUN mkdir -p /usr/local/games
COPY worm.sh /usr/local/games/worm
COPY motd /etc/motd
RUN chmod +x /usr/local/games/worm

RUN mkdir -p /tmp && chmod 1777 /tmp

RUN adduser -D -s /bin/bash gameuser && \
    echo "gameuser:games" | chpasswd

ENV TERM=xterm-256color

EXPOSE 2323

CMD ["/usr/sbin/telnetd", "-F", "-p", "2323", "-l", "/bin/login"]
