FROM haproxy:latest

RUN apt-get clean \
    && apt-get update \
    && apt-get install -y curl vim \
    && rm -rf /var/lib/apt/lists/*

COPY haproxy.cfg.cluster /usr/local/etc/haproxy/haproxy.cfg
COPY start.sh /
