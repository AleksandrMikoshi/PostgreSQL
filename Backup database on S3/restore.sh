#!/bin/bash

# Checking arguments
if [ $# -lt 4 ]; then
    echo "Usage: $0 <PG_PASSWORD> <HOST> <PORT> <POSTGRESQL_USER> <DATABASE> [BACKDIR]"
    exit 1
fi

# Parameters
PG_PASSWORD="$1"
HOST="$2"
PORT="$3"
POSTGRESQL_USER="$4"
DATABASE="$5"
BACKDIR="${6:-/store/backup}"

TIMESTAMP=$(date +%d.%m.%Y)
LOG_DIR="/store/logs"
RESTORE_LOG="$LOG_DIR/restore_${DATABASE}_${TIMESTAMP}.log"

# Create a directory for logs and a file in advance
touch "$RESTORE_LOG" || { echo "Unable to create log file"; exit 1; }

{
    echo "=======================Data Restore======================="
    echo "$(date) - Beginning of restoration $DATABASE"
    echo "Starting to restore the database - $(date '+%d.%m.%Y %H:%M:%S')"
    echo "Host: $HOST"
    echo "User: $POSTGRESQL_USER"
    echo "Port: $PORT"
    echo "Backup directory: $BACKDIR"
    echo "Log file: $RESTORE_LOG"
    echo "=======================Start Restore======================="

    # Checking the backup
    if [ ! -d "$BACKDIR" ]; then
        echo "ERROR: Backup directory not found"
        exit 1
    fi

    # Restore
    echo "Running pg_restore..."
        PGPASSWORD="$PG_PASSWORD" pg_restore --dbname "$DATABASE" \
        --host "$HOST" \
        --username "$POSTGRESQL_USER" \
        --port "$PORT" \
        --format=d \
        --no-owner \
        --no-privileges \
        --clean \
        --if-exists \
        --jobs 15 \
        "$BACKDIR" >> "$RESTORE_LOG" 2>&1

        restore_status=$?

        # Analysis of results with exception of mchar error
        if [ $restore_status -eq 0 ] || (grep -q "DROP EXTENSION IF EXISTS mchar" "$RESTORE_LOG" && [ $(grep -c "ERROR:" "$RESTORE_LOG") -le 1 ]); then
            echo "The recovery process has been completed successfully."
            echo "Completion time - $(date '+%d.%m.%Y %H:%M:%S')"
            echo "=======================Success Restore======================="

            # Проверка предупреждений
            if grep -q "WARNING:" "$RESTORE_LOG"; then
                WARN_MSG=$(grep -m1 "WARNING:" "$RESTORE_LOG")
                echo "WARNING: $WARN_MSG"
            fi
            exit 0
        else
            ERR_MSG=$(grep -A1 "ERROR:" "$RESTORE_LOG" | grep -v "DROP EXTENSION IF EXISTS mchar" | head -n 2 | tr '\n' ' ' || echo "Unknown error")
            echo "$(date) - ERROR: $DATABASE recovery completed with code $restore_status"
            echo "Details: $ERR_MSG"
            echo "=======================Error Restore======================="
            exit 1
        fi
} | tee -a "$RESTORE_LOG"