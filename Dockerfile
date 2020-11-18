ARG DOCKER=19.03.13-dind-rootless
FROM docker:${DOCKER}

ARG CRUN_VERSION=0.15

USER root

RUN mkdir -p /usr/local/bin/ \
    && wget -O crun https://github.com/containers/crun/releases/download/${CRUN_VERSION}/crun-${CRUN_VERSION}-linux-amd64-disable-systemd \
    && chmod 755 crun \
    && mv crun /usr/local/bin/

RUN wget -O fuse-overlayfs https://github.com/containers/fuse-overlayfs/releases/download/v1.2.0/fuse-overlayfs-x86_64 \
    && chmod 755 fuse-overlayfs \
    && mv fuse-overlayfs /usr/local/bin/

RUN mkdir -p /opt/containerd/bin \
    && mkdir -p /opt/containerd/lib

RUN set -eux; \
    adduser -h /home/rootless2 -g 'Rootless2' -D -u 1337 rootless2; \
    echo 'rootless2:165536:65536' >> /etc/subuid; \
    echo 'rootless2:165536:65536' >> /etc/subgid

# pre-create "/var/lib/docker" for our rootless user
RUN set -eux; \
    mkdir -p /home/rootless2/.local/share/docker; \
    chown -R rootless2:rootless2 /home/rootless/.local/share/docker

USER rootless
