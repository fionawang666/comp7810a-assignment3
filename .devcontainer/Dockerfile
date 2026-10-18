# Derived from the professor's rwa-lab-2026 devcontainer Dockerfile.
# Add Python 3 / ZIP utilities for authentic test logs and safe Moodle packaging.
FROM debian:bookworm-slim

ARG APT_MIRROR=deb.debian.org
ARG FOUNDRY_VERSION=v1.8.3
ARG MIRROR_PREFIX=https://gh-proxy.com/
ENV DEBIAN_FRONTEND=noninteractive

RUN if [ "$APT_MIRROR" != "deb.debian.org" ]; then \
      for f in /etc/apt/sources.list /etc/apt/sources.list.d/debian.sources; do \
        [ -f "$f" ] && sed -i "s|deb.debian.org|${APT_MIRROR}|g" "$f"; \
      done; \
    fi \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates curl tar git make python3 zip unzip \
 && rm -rf /var/lib/apt/lists/*

COPY scripts/install-foundry-cn.sh /tmp/install-foundry-cn.sh
RUN FOUNDRY_VERSION="${FOUNDRY_VERSION}" \
    MIRROR_PREFIX="${MIRROR_PREFIX}" \
    FOUNDRY_BIN_DIR=/usr/local/bin \
    bash /tmp/install-foundry-cn.sh \
 && rm -f /tmp/install-foundry-cn.sh

RUN forge --version && cast --version && anvil --version && python3 --version
