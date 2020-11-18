FROM docker:20.10-rc-dind

# busybox "ip" is insufficient:
#   [rootlesskit:child ] error: executing [[ip tuntap add name tap0 mode tap] [ip link set tap0 address 02:50:00:00:00:01]]: exit status 1
RUN apk add --no-cache iproute2

# "/run/user/UID" will be used by default as the value of XDG_RUNTIME_DIR
RUN mkdir /run/user && chmod 1777 /run/user

# create a default user preconfigured for running rootless dockerd
RUN set -eux; \
    adduser -h /home/rootless -g 'Rootless' -D -u 1000 rootless; \
    echo 'rootless:100000:65536' >> /etc/subuid; \
    echo 'rootless:100000:65536' >> /etc/subgid

RUN set -eux; \
    \
    apkArch="$(apk --print-arch)"; \
    case "$apkArch" in \
        'x86_64') \
            url='https://download.docker.com/linux/static/test/x86_64/docker-rootless-extras-20.10.0-rc1.tgz'; \
            ;; \
        *) echo >&2 "error: unsupported architecture ($apkArch)"; exit 1 ;; \
    esac; \
    \
    wget -O rootless.tgz "$url"; \
    \
    tar --extract \
        --file rootless.tgz \
        --strip-components 1 \
        --directory /usr/local/bin/ \
        'docker-rootless-extras/vpnkit' \
    ; \
    rm rootless.tgz; \
    \
# we download/build rootlesskit separately to get a newer release
#	rootlesskit --version; \
    vpnkit --version

# https://github.com/rootless-containers/rootlesskit/releases
ENV ROOTLESSKIT_VERSION 0.11.0

RUN set -eux; \
    apk add --no-cache --virtual .rootlesskit-build-deps \
        go \
        libc-dev \
    ; \
    wget -O rootlesskit.tgz "https://github.com/rootless-containers/rootlesskit/archive/v${ROOTLESSKIT_VERSION}.tar.gz"; \
    export GOPATH='/go'; mkdir "$GOPATH"; \
    mkdir -p "$GOPATH/src/github.com/rootless-containers/rootlesskit"; \
    tar --extract --file rootlesskit.tgz --directory "$GOPATH/src/github.com/rootless-containers/rootlesskit" --strip-components 1; \
    rm rootlesskit.tgz; \
    go build -o /usr/local/bin/rootlesskit github.com/rootless-containers/rootlesskit/cmd/rootlesskit; \
    go build -o /usr/local/bin/rootlesskit-docker-proxy github.com/rootless-containers/rootlesskit/cmd/rootlesskit-docker-proxy; \
    rm -rf "$GOPATH"; \
    apk del --no-network .rootlesskit-build-deps; \
    rootlesskit --version

# pre-create "/var/lib/docker" for our rootless user
RUN set -eux; \
    mkdir -p /home/rootless/.local/share/docker; \
    chown -R rootless:rootless /home/rootless/.local/share/docker

ARG CRUN_VERSION=0.15

RUN mkdir -p /usr/local/bin/ \
    && wget -O crun https://github.com/containers/crun/releases/download/${CRUN_VERSION}/crun-${CRUN_VERSION}-linux-amd64-disable-systemd \
    && chmod 755 crun \
    && mv crun /usr/local/bin/

RUN wget -O fuse-overlayfs https://github.com/containers/fuse-overlayfs/releases/download/v1.2.0/fuse-overlayfs-x86_64 \
    && chmod 755 fuse-overlayfs \
    && mv fuse-overlayfs /usr/local/bin/

RUN mkdir -p /opt/containerd/bin \
    && mkdir -p /opt/containerd/lib

USER rootless
