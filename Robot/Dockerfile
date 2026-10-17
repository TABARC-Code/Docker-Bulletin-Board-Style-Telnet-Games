FROM alpine:3.19

LABEL org.opencontainers.image.title="robots" \
      org.opencontainers.image.description="Classic ASCII robots dodging game served via telnet" \
      org.opencontainers.image.source="https://github.com/TABARC-Code/Docker-Bulletin-Board-Style-Telnet-Games"

RUN apk add --no-cache \
    bash \
    busybox-extras \
    ncurses \
    ncurses-terminfo
# Its bloody 5:12 am damm i need slwwp
RUN mkdir -p /usr/local/games
COPY Robots.sh /usr/local/games/robots
COPY motd /etc/motd
RUN chmod +x /usr/local/games/robots

RUN mkdir -p /tmp && chmod 1777 /tmp

RUN adduser -D -s /bin/bash gameuser && \
    echo "gameuser:games" | chpasswd

ENV TERM=xterm-256color

EXPOSE 2323

CMD ["/usr/sbin/telnetd", "-F", "-p", "2323", "-l", "/bin/login"]
