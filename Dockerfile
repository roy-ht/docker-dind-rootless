ARG FROM=19.03.13-dind-rootless
FROM docker:${FROM}

ARG CRUN_VERSION=0.15

USER root

RUN mkdir -p /usr/local/bin/ \
    && wget -O crun https://github.com/containers/crun/releases/download/${CRUN_VERSION}/crun-${CRUN_VERSION}-linux-amd64-disable-systemd \
    && chmod 755 crun \
    && mv crun /usr/local/bin/

USER rootless
