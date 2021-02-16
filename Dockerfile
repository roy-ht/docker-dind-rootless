ARG DOCKER=20.10.0-dind
FROM docker:${DOCKER}

# COPIED FROM: https://github.com/docker-library/docker/blob/master/20.10/dind-rootless/Dockerfile

# busybox "ip" is insufficient:
#   [rootlesskit:child ] error: executing [[ip tuntap add name tap0 mode tap] [ip link set tap0 address 02:50:00:00:00:01]]: exit status 1
RUN apk add --no-cache iproute2

# "/run/user/UID" will be used by default as the value of XDG_RUNTIME_DIR
RUN mkdir /run/user && chmod 1777 /run/user

# create a default user preconfigured for running rootless dockerd
# some container includes an large number of uid/gids. See https://github.com/rootless-containers/usernetes/issues/55
RUN set -eux; \
	adduser -h /home/rootless -g 'Rootless' -D -u 1000 rootless; \
	echo 'dockremap:100000:65536' > /etc/subuid; \
	echo 'dockremap:100000:65536' > /etc/subgid; \
	echo 'rootless:165536:655360' >> /etc/subuid; \
	echo 'rootless:165536:655360' >> /etc/subgid


RUN set -eux; \
	\
	apkArch="$(apk --print-arch)"; \
	case "$apkArch" in \
		'x86_64') \
			url='https://download.docker.com/linux/static/stable/x86_64/docker-rootless-extras-20.10.2.tgz'; \
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
		'docker-rootless-extras/rootlesskit' \
		'docker-rootless-extras/rootlesskit-docker-proxy' \
		'docker-rootless-extras/vpnkit' \
	; \
	rm rootless.tgz; \
	\
	rootlesskit --version; \
	vpnkit --version

# pre-create "/var/lib/docker" for our rootless user
RUN set -eux; \
	mkdir -p /home/rootless/.local/share/docker; \
	chown -R rootless:rootless /home/rootless/.local/share/docker


RUN apk --no-cache add shadow

# modify group
RUN set -eux \
    && groupmod -g 1337 rootless \
    && find / -group 1000 -exec chgrp -v 1337 '{}' \;

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
