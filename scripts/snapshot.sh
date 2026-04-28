#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="${ROOT_DIR}/dist"
TARGET_URL="https://pro.poiyomi.com/"
BASE_URL="https://pro.poiyomi.com"

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

REL_RE='\.\./(entry|chunks|nodes|assets)/[A-Za-z0-9._-]+\.(js|css)'

seen_file="$(mktemp)"
candidates_file="$(mktemp)"
new_file="$(mktemp)"
trap 'rm -f "${seen_file}" "${candidates_file}" "${new_file}"' EXIT

cd "${DIST_DIR}"

find _app/immutable -type f \( -name '*.js' -o -name '*.css' \) \
  | sort -u >"${seen_file}"

while :; do
  find _app/immutable -type f -name '*.js' -exec grep -hoE "${REL_RE}" {} + \
    | sed 's|^\.\./|_app/immutable/|' \
    | sort -u >"${candidates_file}" \
    || true

  comm -23 "${candidates_file}" "${seen_file}" >"${new_file}"

  [ -s "${new_file}" ] || break

  sed "s|^|${BASE_URL}/|" "${new_file}" \
    | wget \
        --no-host-directories \
        --force-directories \
        --domains=pro.poiyomi.com \
        --execute robots=off \
        --input-file=-

  cat "${new_file}" >>"${seen_file}"
  sort -u "${seen_file}" -o "${seen_file}"
done
