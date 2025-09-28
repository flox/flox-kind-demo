FROM kindest/node:v1.34.0

ENV FLOX_DISABLE_METRICS=true
ARG SHELL=/bin/bash

RUN apt update && apt install -y --no-install-recommends \
	sudo \
	xz-utils \
	&& rm -rf /var/lib/apt/lists/*

RUN curl -Lo /tmp/flox.x86_64-linux.deb https://flox.dev/downloads/debian-archive/flox.x86_64-linux.deb \
	&& dpkg -i /tmp/flox.x86_64-linux.deb \
	&& rm /tmp/flox.x86_64-linux.deb

RUN flox activate -r flox-public/containerd-shim-flox-installer --trust
