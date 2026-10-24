# PHP 8.5 is the newest PHP release published for the devcontainers PHP image.
FROM mcr.microsoft.com/devcontainers/php:8.5

# MariaDB server/client, plus the libraries needed to build the zip extension.
# json, mbstring and readline are already compiled into the base image;
# pcntl, pdo_mysql, shmop and zip have to be added.
RUN apt-get update \
    && export DEBIAN_FRONTEND=noninteractive \
    && apt-get install -y --no-install-recommends mariadb-server mariadb-client libzip-dev \
    && docker-php-ext-install -j"$(nproc)" pcntl pdo_mysql shmop zip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Make sure a php.ini exists and that no functions are disabled.
RUN if [ ! -f "$PHP_INI_DIR/php.ini" ]; then \
        cp "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"; \
    fi \
    && find "$PHP_INI_DIR" -name '*.ini' -exec sed -ri 's/^[[:space:]]*(disable_functions[[:space:]]*=)/;\1/' {} + \
    && php -r 'exit(ini_get("disable_functions") === "" ? 0 : 1);'
RUN sed -i -r 's/^disable_functions/;disable_functions/' /usr/local/etc/php/php.ini

# PHP's built-in default socket (/tmp/mysql.sock) doesn't match Debian's MariaDB,
# so connections to "localhost" would fail with SQLSTATE[HY000] [2002].
RUN printf 'pdo_mysql.default_socket = /run/mysqld/mysqld.sock\nmysqli.default_socket = /run/mysqld/mysqld.sock\n' \
        > "$PHP_INI_DIR/conf.d/zz-mysql-socket.ini"

# Fail the build early if any required extension is missing.
RUN for ext in json mbstring pcntl pdo_mysql readline shmop zip; do \
        php -m | grep -qix "$ext" || { echo "missing PHP extension: $ext" >&2; exit 1; }; \
    done
