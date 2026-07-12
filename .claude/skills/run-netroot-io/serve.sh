#!/usr/bin/env bash
# Launches the real nginx.conf (same one the Dockerfile ships) against
# this repo's static files, on the macOS Homebrew nginx binary — no
# Docker required. Substitutes $PORT the same way the Dockerfile's
# CMD does, and rewrites the docroot from the container path to this
# checkout.
set -euo pipefail

PORT="${1:-8899}"
UNIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
RUN_DIR="/tmp/netroot-io-nginx-test"

if ! command -v nginx >/dev/null 2>&1; then
  echo "nginx not found. Install it with: brew install nginx" >&2
  exit 1
fi

mkdir -p "$RUN_DIR/logs"

sed "s/\$PORT/${PORT}/g; s|root /usr/share/nginx/html|root ${UNIT_DIR}|" \
  "$UNIT_DIR/nginx.conf" > "$RUN_DIR/server.conf"

cat > "$RUN_DIR/nginx.conf" << EOF
worker_processes 1;
error_log ${RUN_DIR}/logs/error.log;
pid ${RUN_DIR}/nginx.pid;
events { worker_connections 64; }
http {
    include $(dirname "$(command -v nginx)")/../etc/nginx/mime.types;
    default_type application/octet-stream;
    access_log ${RUN_DIR}/logs/access.log;
    include ${RUN_DIR}/server.conf;
}
EOF

nginx -c "$RUN_DIR/nginx.conf" -p "$RUN_DIR/"
echo "Serving $UNIT_DIR on http://127.0.0.1:${PORT}/ (pid file: $RUN_DIR/nginx.pid)"
echo "Stop with: nginx -c $RUN_DIR/nginx.conf -p $RUN_DIR/ -s stop"
