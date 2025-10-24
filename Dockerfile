FROM kindest/node:v1.34.0

ENV FLOX_DISABLE_METRICS=true
ARG SHELL=/bin/bash

ARG TARGETARCH

RUN apt update && apt install -y --no-install-recommends \
    sudo \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    case "${TARGETARCH}" in \
      amd64) PKG_ARCH="x86_64" ;; \
      arm64) PKG_ARCH="aarch64" ;; \
      *) echo "Unsupported arch: ${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    curl -Lo /tmp/flox.${PKG_ARCH}-linux.deb https://flox.dev/downloads/debian-archive/flox.${PKG_ARCH}-linux.deb \
	&& dpkg -i /tmp/flox.${PKG_ARCH}-linux.deb \
	&& rm /tmp/flox.${PKG_ARCH}-linux.deb

RUN flox activate -r flox/containerd-shim-flox-installer --trust