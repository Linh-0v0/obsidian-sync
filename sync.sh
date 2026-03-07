#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/.env"

LOG_FILE="$SCRIPT_DIR/sync.log"
ERROR_LOG="$SCRIPT_DIR/sync-errors.log"
MAX_RETRIES=3
RETRY_DELAY=60

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

run_sync() {
    rclone bisync "$VAULT_PATH" "$DRIVE_REMOTE" \
        --create-empty-src-dirs \
        --compare size,modtime \
        --conflict-resolve newer \
        --conflict-suffix "conflict-{DateOnly}" \
        --resilient \
        --recover \
        --max-lock 5m \
        --log-file "$LOG_FILE" \
        --log-level INFO
}

log "Starting sync: $VAULT_PATH <-> $DRIVE_REMOTE"

for attempt in $(seq 1 $MAX_RETRIES); do
    if run_sync; then
        log "Sync completed successfully."
        exit 0
    else
        log "Sync failed (attempt $attempt/$MAX_RETRIES)."
        if [ "$attempt" -lt "$MAX_RETRIES" ]; then
            log "Retrying in ${RETRY_DELAY}s..."
            sleep "$RETRY_DELAY"
        fi
    fi
done

log "All $MAX_RETRIES attempts failed. See $ERROR_LOG for details."
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Sync failed after $MAX_RETRIES retries." >> "$ERROR_LOG"
exit 1
