#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="${ROOT_DIR}/dist"
TARGET_URL="https://pro.poiyomi.com/"

rm -rf "${DIST_DIR}"
mkdir -p "${DIST_DIR}"

wget \
  --recursive \
  --level=1 \
  --page-requisites \
  --follow-tags=link,script,img \
  --ignore-tags=a \
  --convert-links \
  --adjust-extension \
  --no-host-directories \
  --domains=pro.poiyomi.com \
  --no-parent \
  --execute robots=off \
  --directory-prefix="${DIST_DIR}" \
  "${TARGET_URL}"
