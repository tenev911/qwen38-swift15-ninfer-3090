#!/bin/sh
set -eu

exec ninfer-serve \
    /workspace/models/Swift-1.5-Qwen3.8-27b.ninfer \
    --host 0.0.0.0 \
    --port 8080 \
    --api-key "${NINFER_API_KEY}" \
    --max-concurrency 4 \
    --max-context 100000 \
    --kv-capacity 172032 \
    --spec dflash2 \
    --draft-tokens 7 \
    --lm-head-draft \
    --embedding-q4 \
    --gdn-state-fp16 \
    --prefill-cublas \
    --prefill-chunk 4096 \
    --max-pending-requests 16 \
    --pending-timeout-ms 600000 \
    --vision \
    --vision-residency overlay \
    --vision-max-merged 2048 \
    --max-private-continuations 8 \
    --max-shared-prefixes 8 \
    --host-state-slots 4 \
    --host-kv-mib 8192 \
    --auto-prefix-grid
