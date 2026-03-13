#!/usr/bin/env bash
set -euo pipefail

API_BASE="https://us-central1-poiyomi-pro-site.cloudfunctions.net"
WEB_BASE="https://pro.poiyomi.com"
TARGET_VERSION="${1:-10.0.3}"

session_id="$(
  curl -fsS \
    -H 'Content-Type: application/json' \
    -d "{\"data\":{\"version\":\"$TARGET_VERSION\"}}" \
    "$API_BASE/startUnityAuth" | jq -r '.result.sessionId'
)"

auth_url="$WEB_BASE/unity-auth?sessionId=$session_id&version=$TARGET_VERSION"

echo "Open to Authorize:"
echo "$auth_url"

for _ in $(seq 1 150); do
  sleep 2
  resp="$(
    curl -fsS \
      -H 'Content-Type: application/json' \
      -d "{\"data\":{\"sessionId\":\"$session_id\"}}" \
      "$API_BASE/checkUnityAuth" || true
  )"

  status="$(jq -r '.result.status // empty' <<<"$resp" 2>/dev/null || true)"
  url="$(jq -r '.result.downloadUrl // empty' <<<"$resp" 2>/dev/null || true)"

  if [[ "$status" == "completed" && -n "$url" ]]; then
    echo "Open to Download:"
    echo "$url"
    exit 0
  fi

  if [[ "$status" == "failed" ]]; then
    jq . <<<"$resp" >&2 || echo "$resp" >&2
    exit 1
  fi
done

echo "Timed out" >&2
exit 1