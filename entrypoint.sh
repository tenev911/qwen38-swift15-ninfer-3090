#!/bin/bash

set -euo pipefail

MODEL_DIR="/workspace/models"
MODEL_FILE="${MODEL_DIR}/qwen3_8_27b.ninfer"
PARTIAL_FILE="${MODEL_FILE}.partial"

MODEL_URL="${MODEL_URL:-https://huggingface.co/Don-Chad/qwen3.8-27b-ninfer/resolve/main/qwen3_8_27b.ninfer?download=true}"

mkdir -p "${MODEL_DIR}"

echo "========================================"
echo " NInfer-3090 / Qwen3.8-27B"
echo "========================================"
echo "Model directory : ${MODEL_DIR}"
echo "Model           : ${MODEL_FILE}"
echo "Port            : 8080"
echo

if [ -f "${MODEL_FILE}" ]; then

    echo "[model] Model already exists."
    ls -lh "${MODEL_FILE}"

else

    echo "[model] Model not found."
    echo "[model] Downloading..."
    echo
    echo "${MODEL_URL}"
    echo

    wget \
        --continue \
        --show-progress \
        --progress=bar:force \
        --output-document="${PARTIAL_FILE}" \
        "${MODEL_URL}"

    mv "${PARTIAL_FILE}" "${MODEL_FILE}"

    echo
    echo "[model] Download completed."
    ls -lh "${MODEL_FILE}"

fi

echo
echo "[ninfer] Starting server..."
echo

exec /usr/local/bin/ninfer-serve \
    "${MODEL_FILE}" \
    --host 0.0.0.0 \
    --port 8080
