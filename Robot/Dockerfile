## `Dockerfile`

```dockerfile
FROM alpine:3.19

RUN apk add --no-cache \
    bash \
    busybox-extras \
    ncurses \
    ncurses-terminfo
# Its bloody 5:12 am damm i need slwwp
RUN mkdir -p /usr/local/games
COPY robots.sh /usr/local/games/robots
COPY motd /etc/motd
RUN chmod +x /usr/local/games/robots

RUN mkdir -p /tmp && chmod 1777 /tmp

RUN adduser -D -s /bin/bash gameuser && \
    echo "gameuser:games" | chpasswd

ENV TERM=xterm-256color

EXPOSE 2323

CMD ["/usr/sbin/telnetd", "-F", "-p", "2323", "-l", "/bin/login"]
