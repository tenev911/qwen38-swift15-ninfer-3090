#!/bin/bash

set -euo pipefail

MODEL_DIR="/workspace/models"
MODEL_FILE="${MODEL_DIR}/qwen3_8_27b.ninfer"

# Official Qwen3.8-27B NInfer artifact.
MODEL_URL="https://huggingface.co/Don-Chad/qwen3.8-27b-ninfer/resolve/main/qwen3_8_27b.ninfer?download=true"

mkdir -p "${MODEL_DIR}"

echo "========================================"
echo " NInfer-3090 / Qwen3.8-27B"
echo "========================================"
echo "Model: ${MODEL_FILE}"
echo "Port : 8080"
echo

if [ -f "${MODEL_FILE}" ]; then
    echo "[model] Already present:"
    ls -lh "${MODEL_FILE}"
else
    echo "[model] Not found."
    echo "[model] Downloading Qwen3.8-27B..."
    echo "[model] URL: ${MODEL_URL}"
    echo

    # -c / --continue allows the download to resume
    # if the connection/container is interrupted.
    wget \
        --continue \
        --show-progress \
        --progress=bar:force \
        --output-document="${MODEL_FILE}.partial" \
        "${MODEL_URL}"

    # Only expose the final filename after the download
    # has completed successfully.
    mv "${MODEL_FILE}.partial" "${MODEL_FILE}"

    echo
    echo "[model] Download complete:"
    ls -lh "${MODEL_FILE}"
fi

echo
echo "[ninfer] Starting server..."
echo

exec /usr/local/bin/ninfer-serve \
    "${MODEL_FILE}" \
    --host 0.0.0.0 \
    --port 8080
