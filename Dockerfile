FROM alpine:3.13
LABEL maintainer="developer@tobias-heckel.de"

# Build arguments need to be passed to `docker build` with `--build-arg KEY=VALUE`

# BUILD_DATE is the datetime the image was build and is used in a label
# BUILD_DATE should be formatted according to RFC 3339:
# BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
ARG BUILD_DATE

# BUILD_VERSION determines which version of syncthing is used for the image
# BUILD_VERSION must be the tag name of the release on GitHub without `v`, e.g. `1.0.0`
# BUILD_VERSION=$(curl -s https://api.github.com/repos/syncthing/syncthing/releases/latest | jq -r .tag_name )
# BUILD_VERSION=${BUILD_VERSION:1}
ARG BUILD_VERSION

# Labels
# Label Schema 1.0.0-rc.1 (http://label-schema.org/rc1/)
LABEL org.label-schema.schema-version="1.0"
LABEL org.label-schema.build-date=$BUILD_DATE
LABEL org.label-schema.version=$BUILD_VERSION
LABEL org.label-schema.name="strobi/rpi-syncthing"
LABEL org.label-schema.description="Syncthing for Raspberry Pi on ARMv7"
LABEL org.label-schema.url="https://syncthing.net"
LABEL org.label-schema.vcs-url="https://github.com/syncthing/syncthing"
LABEL org.label-schema.docker.cmd="docker run -d -p 8384:8384 -p 22000:22000 -p 21027:21027 -v ~/syncthing/config:/syncthing/config -v ~/syncthing/data:/syncthing/data strobi/rpi-syncthing"

# Ports that are listened on in the container
# Can be matched to other ports on the host via `docker run`
EXPOSE 8384/tcp 22000/tcp 21027/udp

# Directories in the container that are mounted from the host
VOLUME /syncthing/config /syncthing/data

# Checks whether syncthing is listening on port 22000
# Enables docker to automatically restart containers if they are not healthy
HEALTHCHECK --interval=1m --timeout=10s \
    CMD nc -z localhost 22000 || exit 1

# Default environment variables for syncthing
ENV STNOUPGRADE=1

# Create syncthing group and user
# UID and GID in container must match those of user on host (usually pi: 1000)
RUN addgroup \
        -g 1000 \
        syncthing \
    && adduser \
        -D -H \
        -u 1000 \
        -h /syncthing \
        -G syncthing \
        -s /sbin/nologin \
        -g "" \
        syncthing

# Install build dependencies (will be deleted from the image after the build)
RUN apk --no-cache --virtual .build-deps add \
        apache2-utils \
        curl \
        gnupg

# Install dependencies
RUN apk --no-cache add \
        apr \
        apr-util \
        ca-certificates \
        xmlstarlet

# Get syncthing and verify signature
RUN gpg --keyserver keyserver.ubuntu.com --recv-key D26E6ED000654A3E \
    && cp /usr/bin/htpasswd /tmp \
    && set -x \
    && curl -sLO https://github.com/syncthing/syncthing/releases/download/v${BUILD_VERSION}/syncthing-linux-arm-v${BUILD_VERSION}.tar.gz \
    && curl -sLO https://github.com/syncthing/syncthing/releases/download/v${BUILD_VERSION}/sha256sum.txt.asc \
    && gpg --verify sha256sum.txt.asc \
    && grep syncthing-linux-arm- sha256sum.txt.asc | sha256sum -c \
    && tar -zxf syncthing-linux-arm-v${BUILD_VERSION}.tar.gz \
    && mv syncthing-linux-arm-v${BUILD_VERSION}/syncthing /usr/local/bin/syncthing \
    && rm -rf syncthing-linux-arm-v${BUILD_VERSION} sha256sum.txt.asc syncthing-linux-arm-v${BUILD_VERSION}.tar.gz \
    && rm -rf /root/.gnupg

# Delete build dependencies
RUN apk del .build-deps \
    && mv /tmp/htpasswd /usr/bin/htpasswd

USER syncthing

# Create volume directories
RUN mkdir -p /syncthing/config \
    && mkdir -p /syncthing/data

# Copy entrypoint to image and make executable
COPY --chown=syncthing:syncthing start.sh /syncthing/
RUN chmod 0755 /syncthing/start.sh

# Entrypoint
CMD /syncthing/start.sh
