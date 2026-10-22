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

# Capture the installer binary into the image at build time, with a Nix GC
# root so it survives `flox gc` and is available offline at node boot.
# The installer's runtime deps (dasel, jq, containerd-shim-flox-v2, etc.)
# are baked into its writeShellApplication closure, so the gcroot retains
# them all — no FloxHub pull needed at boot.
#
# We do NOT run the installer here: at build time there is no systemd-managed
# containerd to patch and restart. Registration happens at node boot via the
# flox-shim-install.service unit below.
RUN flox activate -r flox/containerd-shim-flox-installer --trust -- bash -euc '\
      installer_real="$(readlink -f "$(command -v containerd-shim-flox-installer)")"; \
      nix-store --add-root /nix/var/nix/gcroots/containerd-shim-flox-installer --indirect -r "$installer_real"; \
      mkdir -p /usr/local/bin; \
      ln -fs "$installer_real" /usr/local/bin/containerd-shim-flox-installer; \
    ' \
    && flox delete -f -d /root/.cache/flox/remote/flox/containerd-shim-flox-installer \
    && flox gc \
    && rm -rf /root/.cache /root/.local
COPY flox-shim-install.service /etc/systemd/system/flox-shim-install.service
# Enable by symlink because `systemctl enable` is unavailable during docker build.
RUN ln -s /etc/systemd/system/flox-shim-install.service \
      /etc/systemd/system/multi-user.target.wants/flox-shim-install.service
