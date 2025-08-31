#!/bin/bash

# Checking arguments
if [ $# -lt 5 ]; then
    echo "Usage: $0 <PG_PASSWORD> <HOST> <PORT> <POSTGRESQL_USER> <DATABASE> [BACKDIR] [S3_BUCKET]"
    exit 1
fi

# Parameters
PG_PASSWORD="$1"
HOST="$2"
PORT="$3"
POSTGRESQL_USER="$4"
DATABASE="$5"
BACKDIR="${6:-/store/backup}"
S3_BUCKET="$7"

# Logging settings
TIMESTAMP=$(date +%d.%m.%Y-%H%M)
LOG_DIR="/store/logs"
BACKUP_LOG="$LOG_DIR/pg_backup_${DATABASE}_${TIMESTAMP}.log"
S3_LOG="$LOG_DIR/s3_upload_${DATABASE}_${TIMESTAMP}.log"

# Create directories
mkdir -p "$BACKDIR" "$LOG_DIR" || {
    echo "$(date '+%d.%m.%Y %H:%M:%S') - Failed to create directories" | tee -a "$BACKUP_LOG"
    exit 1
}

# 1. Creating a backup
BACKUP_NAME="${DATABASE}_${TIMESTAMP}"
BACKUP_PATH="$BACKDIR/$BACKUP_NAME"

{
    echo " "
    echo " "
    echo "=======================Data Backup======================="
    echo "Starting to create a database backup $DATABASE"
    echo "Starting backup creation - $(date '+%d.%m.%Y %H:%M:%S')"
    echo "Host: $HOST"
    echo "User: $POSTGRESQL_USER"
    echo "Backup directory: $BACKUP_PATH"
    echo "=======================Start Backup======================="

    echo "Running pg_dump..."
    PGPASSWORD="$PG_PASSWORD" pg_dump \
        --host "$HOST" \
        --port "$PORT" \
        --username "$POSTGRESQL_USER" \
        --dbname "$DATABASE" \
        --format d \
        --jobs 15 \
        --file "$BACKUP_PATH" \
        --no-owner \
        --no-privileges >> "$BACKUP_LOG" 2>&1

    DUMP_EXIT_CODE=$?
    if [ $DUMP_EXIT_CODE -ne 0 ]; then
        echo "ERROR: pg_dump exited with code $DUMP_EXIT_CODE"
        grep -A5 "ERROR:" "$BACKUP_LOG" >> "$BACKUP_LOG"
        exit $DUMP_EXIT_CODE
    fi

    echo "Backup successfully created: $BACKUP_PATH"
    BACKUP_SIZE=$(du -sh "$BACKUP_PATH" | cut -f1)
    echo "Backup size: $BACKUP_SIZE"

    # 2. Upload to S3 (if bucket specified)
    if [ -n "$S3_BUCKET" ]; then
        echo "=======================Data S3======================="
        echo "Starting uploading backup to S3"
        echo "Starting to transfer backup to S3 - $(date '+%d.%m.%Y %H:%M:%S')"
        echo "Bucket S3: $S3_BUCKET"
        echo "Local path: $BACKUP_PATH"
        echo "S3 path: s3://$S3_BUCKET/$BACKUP_NAME"
        echo "=======================Start S3======================="

        echo "Starting aws s3 sync..."
        aws s3 sync "$BACKUP_PATH" "s3://$S3_BUCKET/$BACKUP_NAME" >> "$S3_LOG" 2>&1

        S3_EXIT_CODE=$?
        if [ $S3_EXIT_CODE -ne 0 ]; then
            echo "ERROR: Upload to S3 failed (code $S3_EXIT_CODE)"
            grep -A5 "error" "$S3_LOG" >> "$S3_LOG"
            exit $S3_EXIT_CODE
        fi

        echo "Backup successfully uploaded to S3"
        echo "Integrity check..."

        # Integrity check (compare number of files)
        LOCAL_FILES=$(find "$BACKUP_PATH" -type f | wc -l)
        S3_FILES=$(aws s3 ls "s3://$S3_BUCKET/$BACKUP_NAME/" --recursive | wc -l)

        echo "Local files: $LOCAL_FILES, S3 files: $S3_FILES"

        if [ "$LOCAL_FILES" -ne "$S3_FILES" ]; then
            echo "ERROR: File count mismatch"
            exit 1
        fi

        echo "Backup integrity confirmed"
    fi

    echo "The backup process has been completed successfully."
    echo "Completion time - $(date '+%d.%m.%Y %H:%M:%S')"
    echo "=======================End Backup======================="
    exit 0
} | tee -a "$BACKUP_LOG"