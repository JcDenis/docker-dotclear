# docker-dotclear:latest
# Debian 12.7 / nginx 1.22.1 / php-fpm 8.3

# Base from PHP official FPM image
FROM php:8.3-fpm

# Dotclear version
ENV DOTCLEAR_VERSION 2.31
ENV DOTCLEAR_MD5 ec08bbcee14132ac7bcefb8ce5d415ed

# Required system packages
RUN set -x; \
    apt-get update \
    && apt-get install -y nginx \
    && apt-get install -y --no-install-recommends \
        postgresql-server-dev-all \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
        libonig-dev \
        rsync \
        unzip \
    && rm -r /var/lib/apt/lists/*

# Required php packages
RUN docker-php-ext-install opcache mbstring pgsql mysqli \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd

# Opcache
RUN { \
        echo 'opcache.memory_consumption=128'; \
        echo 'opcache.interned_strings_buffer=8'; \
        echo 'opcache.max_accelerated_files=4000'; \
        echo 'opcache.revalidate_freq=2'; \
        echo 'opcache.fast_shutdown=1'; \
        echo 'opcache.enable_cli=1'; \
    } > /usr/local/etc/php/conf.d/php-opocache-cfg.ini

# Web server configuartion
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
COPY server.conf /etc/nginx/conf.d/default.conf

WORKDIR /var/www/html
EXPOSE 80

# Get Dotclear
RUN mkdir -p /usr/src/dotclear \
    && curl -fsSL -o dotclear.zip "http://download.dotclear.org/attic/dotclear-${DOTCLEAR_VERSION}.zip" \
    && echo "$DOTCLEAR_MD5 dotclear.zip" | md5sum -c - \
    && unzip -d /usr/src dotclear.zip \
    && rm dotclear.zip \
    && chown -R www-data:www-data /usr/src/dotclear \
    && chmod -R 755 /usr/src/dotclear/public /usr/src/dotclear/cache \
    && rm -f /var/www/html/*

# Entrypoint
ADD ../docker-entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

# Container healthcheck
HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1:8080/fpm-ping || exit 1