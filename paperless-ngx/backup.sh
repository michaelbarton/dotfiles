#!/usr/bin/env bash
set -euo pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

LOG_FILE="$HOME/Library/Logs/paperless-backup.log"
STAGING_DIR="$HOME/.paperless-backup-staging"
COMPOSE_FILE="$HOME/.dotfiles/paperless-ngx/docker-compose.yml"

log() {
    echo "[$(date '+%Y-%m-%dT%H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

HEALTHCHECK_PING_URL=$(security find-generic-password -a "$USER" -s paperless-backup-healthcheck-url -w 2>/dev/null || true)

ping_healthcheck() {
    [ -z "$HEALTHCHECK_PING_URL" ] && return 0
    curl -fsS -m 10 --retry 3 -o /dev/null "${HEALTHCHECK_PING_URL}${1:-}" || true
}

on_error() {
    log "Paperless backup failed"
    ping_healthcheck /fail
}
trap on_error ERR

log "Starting paperless backup"

export B2_ACCOUNT_ID
B2_ACCOUNT_ID=$(security find-generic-password -a "$USER" -s paperless-backup-b2-id -w)
export B2_ACCOUNT_KEY
B2_ACCOUNT_KEY=$(security find-generic-password -a "$USER" -s paperless-backup-b2-key -w)
export RESTIC_PASSWORD
RESTIC_PASSWORD=$(security find-generic-password -a "$USER" -s paperless-backup-restic-pw -w)

log "Clearing staging directory"
mkdir -p "$STAGING_DIR"
rm -rf "${STAGING_DIR:?}"/*

log "Running paperless document_exporter"
/Applications/Docker.app/Contents/Resources/bin/docker compose -f "$COMPOSE_FILE" exec -T webserver document_exporter -na -nt -f /usr/src/paperless/backup

log "Running restic backup"
restic -r b2:mb-paperless-backup:paperless backup "$STAGING_DIR"

log "Pruning old snapshots"
restic -r b2:mb-paperless-backup:paperless forget --keep-daily 7 --keep-weekly 2 --keep-monthly 2 --prune

log "Paperless backup complete"
ping_healthcheck
