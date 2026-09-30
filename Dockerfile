FROM nvidia/cuda:13.1.2-runtime-ubuntu24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        wget \
        libavcodec60 \
        libavformat60 \
        libavutil58 \
        libcurl4t64 \
        libswscale7 \
    && rm -rf /var/lib/apt/lists/*

# NInfer sera fourni par le dépôt au moment du build.
COPY ninfer-serve /usr/local/bin/ninfer-serve
COPY ninfer /usr/local/bin/ninfer

RUN chmod +x /usr/local/bin/ninfer-serve /usr/local/bin/ninfer

RUN mkdir -p /workspace/models

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /workspace

EXPOSE 8080

STOPSIGNAL SIGTERM

ENTRYPOINT ["/entrypoint.sh"]
