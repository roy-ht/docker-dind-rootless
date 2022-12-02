#!/bin/sh

if [ -d /home/rootless ]; then
    chown rootless:rootless /home/rootless
fi

exec setpriv --reuid=1000 --regid=1337 --init-groups docker-entrypoint.sh "$@"
