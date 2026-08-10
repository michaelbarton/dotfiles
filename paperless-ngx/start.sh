#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="$HOME/Library/Logs/paperless-start.log"
COMPOSE_FILE="$HOME/.dotfiles/paperless-ngx/docker-compose.yml"
DOCKER="/Applications/Docker.app/Contents/Resources/bin/docker"

log() {
    echo "[$(date '+%Y-%m-%dT%H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

log "Waiting for Docker to be ready"
for i in $(seq 1 60); do
    if "$DOCKER" info >/dev/null 2>&1; then
        break
    fi
    sleep 5
done

if ! "$DOCKER" info >/dev/null 2>&1; then
    log "Docker did not become ready in time, giving up"
    exit 1
fi

log "Starting paperless stack"
"$DOCKER" compose -f "$COMPOSE_FILE" up -d

log "Paperless stack started"
