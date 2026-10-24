#!/bin/sh
# Starts MariaDB inside the dev container and creates the database/user
# that lib/config.php expects. Safe to run repeatedly.
set -e

DB_NAME="${POSTCODIFY_DB_DBNAME:-postcodify}"
DB_USER="${POSTCODIFY_DB_USER:-postcodify}"
DB_PASS="${POSTCODIFY_DB_PASS:-yourpassword}"

if ! sudo mysqladmin ping --silent >/dev/null 2>&1; then
    sudo service mariadb start || (sudo mysqld_safe >/dev/null 2>&1 &)
    i=0
    until sudo mysqladmin ping --silent >/dev/null 2>&1; do
        i=$((i + 1))
        [ "$i" -ge 30 ] && { echo "MariaDB did not start" >&2; exit 1; }
        sleep 1
    done
fi

sudo mariadb <<SQL
CREATE DATABASE IF NOT EXISTS \`$DB_NAME\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
CREATE USER IF NOT EXISTS '$DB_USER'@'127.0.0.1' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO '$DB_USER'@'localhost';
GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO '$DB_USER'@'127.0.0.1';
FLUSH PRIVILEGES;
SQL
