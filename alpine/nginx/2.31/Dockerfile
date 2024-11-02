# docker-dotclear:2.31-anf

##
# Alpine
##

FROM alpine:latest

RUN echo "UTC" > /etc/timezone

##
# Nginx
##

RUN adduser -D -g 'www' www
RUN apk add --no-cache --update \
    nginx \
    curl \
    tar \
    unzip

RUN mkdir -p /var/www/html \
    && chown -R www:www /var/lib/nginx \
    && chown -R www:www /var/www

COPY nginx.conf /etc/nginx/nginx.conf

WORKDIR /var/www/html

##
# PHP
##

ENV VER_PHP php83

RUN apk add --no-cache --update \
    ${VER_PHP}-common \
    ${VER_PHP}-cli \
    ${VER_PHP}-fpm \
    ${VER_PHP}-session \
    ${VER_PHP}-curl \
    ${VER_PHP}-gd \
    ${VER_PHP}-gmp \
    ${VER_PHP}-exif \
    ${VER_PHP}-tidy \
    ${VER_PHP}-intl \
    ${VER_PHP}-json \
    ${VER_PHP}-mbstring \
    ${VER_PHP}-iconv \
    ${VER_PHP}-gettext \
    ${VER_PHP}-mysqli \
    ${VER_PHP}-opcache \
    ${VER_PHP}-dom \
    ${VER_PHP}-xml \
    ${VER_PHP}-simplexml \
    ${VER_PHP}-zip \
    ${VER_PHP}-sqlite3

COPY php.ini /etc/${VER_PHP}/php.ini
COPY php-fpm.conf /etc/${VER_PHP}/php-fpm.d/www.conf

##
# Dotclear
##

ENV VER_DOTCLEAR 2.31
ENV MD5_DOTCLEAR ec08bbcee14132ac7bcefb8ce5d415ed

RUN mkdir -p /usr/src/dotclear \
    && curl -fsSL -o dotclear.zip "http://download.dotclear.org/attic/dotclear-${VER_DOTCLEAR}.zip" \
    && echo "$MD5_DOTCLEAR dotclear.zip" | md5sum -c - \
    && unzip -d /usr/src dotclear.zip \
    && rm dotclear.zip \
    && chown -R www:www /usr/src/dotclear \
    && chmod -R 755 /usr/src/dotclear/public /usr/src/dotclear/cache \
    && rm -f /var/www/html/*

##
# END
##

EXPOSE 80

ADD docker-entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/bin/sh", "/entrypoint.sh"]

HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1:80/fpm-ping || exit 1