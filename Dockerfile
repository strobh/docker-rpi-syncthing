FROM alpine

RUN addgroup -g 1000 syncthing \
    && adduser -D -u 1000 -G syncthing -s /sbin/nologin -g "" -h /syncthing syncthing

RUN mkdir /syncthing/config \
    && mkdir /syncthing/data \
    && mkdir /syncthing/bin

WORKDIR /syncthing/bin

RUN apk add --no-cache --virtual .deps \
         apache2-utils \
         curl \
         gnupg \
         jq \
    && apk add --no-cache \
         ca-certificates \
         xmlstarlet \
    && gpg --keyserver keyserver.ubuntu.com --recv-key D26E6ED000654A3E \
    && cp /usr/bin/htpasswd /tmp \
    && set -x \
    && release=${release:-$(curl -s https://api.github.com/repos/syncthing/syncthing/releases/latest | jq -r .tag_name )} \
    && curl -sLO https://github.com/syncthing/syncthing/releases/download/${release}/syncthing-linux-arm-${release}.tar.gz \
    && curl -sLO https://github.com/syncthing/syncthing/releases/download/${release}/sha256sum.txt.asc \
    && gpg --verify sha256sum.txt.asc \
    && grep syncthing-linux-arm- sha256sum.txt.asc | sha256sum -c \
    && tar -zxf syncthing-linux-arm-${release}.tar.gz \
    && mv syncthing-linux-arm-${release}/syncthing . \
    && rm -rf syncthing-linux-arm-${release} sha256sum.txt.asc syncthing-linux-arm-${release}.tar.gz \
    && apk del .deps \
    && mv /tmp/htpasswd /usr/bin/htpasswd

COPY start.sh .
RUN chmod +x start.sh

RUN chown -R syncthing:syncthing /syncthing

USER syncthing

ENV STNOUPGRADE=1

VOLUME /syncthing/config /syncthing/data

HEALTHCHECK --interval=1m --timeout=10s \
    CMD nc -z localhost 22000 || exit 1

CMD /syncthing/bin/start.sh
