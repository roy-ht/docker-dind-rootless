FROM docker:22.06.0-beta.0-dind-rootless

USER root

# modify group
RUN set -eux \
    && groupmod -g 1337 rootless \
    && find / -group 1000 -exec chgrp -v 1337 '{}' \;

USER rootless

