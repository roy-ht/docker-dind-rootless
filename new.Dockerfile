FROM docker:20.10.21-dind-rootless

USER root

RUN apk --no-cache add shadow

# modify group
RUN set -eux \
    && groupmod -g 1337 rootless \
    && find / -group 1000 -exec chgrp -v 1337 '{}' \;

USER rootless

