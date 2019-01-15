FROM java:8-jre-alpine
MAINTAINER CyberArk
ARG CONJUR_ACCOUNT

ENV CONJUR_ACCOUNT=$CONJUR_ACCOUNT

RUN  apk update \
  && apk add curl tar \
  && mkdir -p /usr/local/lib/summon \
  && cd /usr/local/bin \
  && curl -sSL https://github.com/cyberark/summon/releases/download/v0.6.6/summon-linux-amd64.tar.gz \
      | tar xz \
  && cd /usr/local/lib/summon \
  && curl -sSL https://github.com/cyberark/summon-conjur/releases/download/v0.5.2/summon-conjur-linux-amd64.tar.gz \
      | tar xz

# Fix for summon-conjur dynamically linking to libc
RUN  mkdir -p /lib64 \
  && ln -fs /lib/libc.musl-x86_64.so.1 /lib64/ld-linux-x86-64.so.2;

# Copy cert for TLS
COPY ./conjur-$CONJUR_ACCOUNT.pem /etc

ENTRYPOINT [ "summon", "-f", "/etc/secrets.yml" ]
