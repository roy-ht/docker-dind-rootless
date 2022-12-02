#!/bin/sh

if [ -d /home/rootless/.local/share/docker ]; then
    chown rootless:rootless /home/rootless/.local/share/docker
fi

exec setpriv --reuid=1000 --regid=1337 --init-groups dockerd-entrypoint.sh "$@"
