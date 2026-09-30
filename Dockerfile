# syntax=docker/dockerfile:1

FROM nvidia/cuda:13.1.2-devel-ubuntu24.04 AS build

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    cmake \
    ninja-build \
    pkg-config \
    ca-certificates \
    libavcodec-dev \
    libavformat-dev \
    libavutil-dev \
    libcurl4-openssl-dev \
    libswscale-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src

# NInfer-3090 source
RUN git clone --depth 1 \
    https://github.com/Don-Chad/ninfer-3090.git \
    /src/ninfer-3090

WORKDIR /src/ninfer-3090

RUN cmake -S . -B /build -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_TESTING=OFF \
    && cmake --build /build --parallel


# ============================================================
# Runtime
# ============================================================

FROM nvidia/cuda:13.1.2-runtime-ubuntu24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    wget \
    libavcodec60 \
    libavformat60 \
    libavutil58 \
    libcurl4t64 \
    libswscale7 \
    && rm -rf /var/lib/apt/lists/*

# Remove CUDA compatibility libraries.
# They can cause problems with consumer NVIDIA GPUs such as
# the RTX 3090 when the host driver is newer.
RUN rm -rf \
    /usr/local/cuda-13.1/compat \
    /usr/local/cuda-13/compat \
    /usr/local/cuda/compat

COPY --from=build /build/apps/ninfer /usr/local/bin/ninfer
COPY --from=build /build/apps/ninfer-serve /usr/local/bin/ninfer-serve

RUN mkdir -p /workspace/models

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /workspace

EXPOSE 8080

STOPSIGNAL SIGTERM

ENTRYPOINT ["/entrypoint.sh"]
