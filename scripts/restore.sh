#!/bin/bash

set -e

if [ -z "$1" ]; then
    echo "Usage: ./scripts/restore.sh backup.sql"
    exit 1
fi

source .env

BACKUP_FILE="$1"

echo "Restoring database..."

cat "$BACKUP_FILE" | docker exec -i wordpress-mysql \
  mysql \
  -u"$MYSQL_USER" \
  -p"$MYSQL_PASSWORD" \
  "$MYSQL_DATABASE"

echo "Database restored successfully."