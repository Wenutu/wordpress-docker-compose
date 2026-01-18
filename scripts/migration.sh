#!/bin/bash

# 1. Determine project root (assuming script is in wordpress/scripts/)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# 2. Load .env to get DATA_PATH (only used to determine where to save backup)
if [ -f "$PROJECT_ROOT/.env" ]; then
    set -a
    source "$PROJECT_ROOT/.env"
    set +a
else
    echo "Warning: .env file not found, defaulting DATA_PATH to ./data"
    DATA_PATH="./data"
fi

# 3. Calculate absolute path for backup file
if [[ "$DATA_PATH" == ./* ]]; then
    # If it is a relative path, convert it to absolute path relative to project root
    BACKUP_DIR="$PROJECT_ROOT/${DATA_PATH#./}/backup"
else
    BACKUP_DIR="$DATA_PATH/backup"
fi

# Ensure backup directory exists
mkdir -p "$BACKUP_DIR"

_now=$(date +"%Y_%m_%d_%H%M%S")
_file="$BACKUP_DIR/data_$_now.sql"

echo "------------------------------------------------"
echo "Starting Database Backup..."
echo "Container Service: db"
echo "Output File:       $_file"
echo "------------------------------------------------"

# 4. Execute export
# Use cd to switch to project root to ensure docker-compose can find the yaml file
# Use internal $MARIADB_... env vars inside container, no need to pass password on host
cd "$PROJECT_ROOT" && docker-compose exec -T db sh -c 'mariadb-dump "$MARIADB_DATABASE" -u"$MARIADB_USER" -p"$MARIADB_PASSWORD"' > "$_file"

if [ $? -eq 0 ]; then
    echo "✅ Backup completed successfully."
    ls -lh "$_file"
else
    echo "❌ Backup failed."
    rm -f "$_file" # Delete potential empty or error file
    exit 1
fi