FROM kindest/node:v1.36.1

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

# https://github.com/NixOS/nix/issues/5258
RUN echo "filter-syscalls = false" >> /etc/nix/flox.conf

# Run the installer binary directly from the Catalog package.
# The Catalog package requires FloxHub auth; the token is injected as a
# BuildKit secret so it never lands in a layer. The auth state and Catalog
# cache are both removed by the rm below.
RUN --mount=type=secret,id=floxhub_token \
    flox auth login --insecure-storage --once --token-file=/run/secrets/floxhub_token \
    && flox run -p flox/containerd-shim-flox-installer -- containerd-shim-flox-installer \
    && flox gc \
    && rm -rf /root/.cache /root/.local
