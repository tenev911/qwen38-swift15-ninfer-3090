# syntax=docker/dockerfile:1

# ---------------------------------------------------------------------------
# Build NInfer-3090 for RTX 3090 / 3090 Ti (SM86)
# ---------------------------------------------------------------------------

FROM nvidia/cuda:13.1.2-devel-ubuntu24.04 AS build

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
        ca-certificates \
        cmake \
        curl \
        git \
        libavcodec-dev \
        libavformat-dev \
        libavutil-dev \
        libcurl4-openssl-dev \
        libswscale-dev \
        ninja-build \
        pkg-config \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src

# NInfer-3090 is specifically adapted for RTX 3090 / SM86.
# We deliberately build from this fork rather than upstream NInfer.
RUN git clone --depth 1 \
    https://github.com/Don-Chad/ninfer-3090.git \
    .

RUN cmake -S . -B /build -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DNINFER_BUILD_APPS=ON \
        -DBUILD_TESTING=OFF \
        -DNINFER_BUILD_BENCHMARKS=OFF \
    && cmake --build /build \
        --parallel \
        --target ninfer ninfer-serve


# ---------------------------------------------------------------------------
# Runtime
# ---------------------------------------------------------------------------

FROM nvidia/cuda:13.1.2-runtime-ubuntu24.04

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
        ca-certificates \
        curl \
        libavcodec60 \
        libavformat60 \
        libavutil58 \
        libcurl4t64 \
        libswscale7 \
    && rm -rf /var/lib/apt/lists/*

# IMPORTANT:
# CUDA runtime images can contain forward-compatibility libraries.
# On GeForce cards these can trigger:
#
#   cudaErrorCompatNotSupportedOnDevice
#
# The NInfer-3090 Dockerfile explicitly removes them.
RUN rm -rf \
        /usr/local/cuda-13.1/compat \
        /usr/local/cuda-13/compat \
        /usr/local/cuda/compat

COPY --from=build \
    /build/apps/ninfer \
    /usr/local/bin/ninfer

COPY --from=build \
    /build/apps/ninfer-serve \
    /usr/local/bin/ninfer-serve


# ---------------------------------------------------------------------------
# Qwen3.8 Swift 1.5 artifact
# ---------------------------------------------------------------------------

WORKDIR /workspace/models

ARG MODEL_REPO="hamixdd/Swift-1.5-Qwen3.8-27B-W4A16-RTX3090-NInfer-v3"
ARG MODEL_FILE="Swift-1.5-Qwen3.8-27b.ninfer"

# The artifact is ~20.4 GB.
#
# Keeping the model INSIDE the image means Salad can reuse the image/cache
# instead of downloading the model from Hugging Face on every container start.
RUN curl --fail --location \
        --retry 10 \
        --retry-all-errors \
        --retry-delay 5 \
        "https://huggingface.co/${MODEL_REPO}/resolve/main/${MODEL_FILE}?download=true" \
        --output "/workspace/models/${MODEL_FILE}"

# ---------------------------------------------------------------------------
# Runtime configuration
#
# This is the exact profile published by the Swift model author:
#
#   172032 context
#   DFlash2 K=7
#   MTP draft head
#   cuBLAS prefill
#   vision
#   4 host state slots
#   8 GiB host KV
#
# It was benchmarked on a single RTX 3090.
# ---------------------------------------------------------------------------

EXPOSE 8080

STOPSIGNAL SIGTERM

HEALTHCHECK --interval=10s --timeout=5s --start-period=30s --retries=180 \
    CMD curl --fail --silent \
        http://127.0.0.1:8080/health \
        > /dev/null || exit 1

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
