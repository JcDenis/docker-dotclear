# docker-dotclear:*
# docker-dotclear Dockerfile

##
# Alpine
##

# Use latest Alpine docker release
FROM alpine:3.21.0

# Set system timezone
RUN echo "UTC" > /etc/timezone

# Select Dotclear release canal (stable | unstable)
ARG CANAL stable
ENV CNL_DOTCLEAR=$CANAL

# Create user
RUN adduser -D -g 'www' www

# Image label
LABEL "org.opencontainers.image.authors"="Jean-Christian Paul Denis"
LABEL "org.opencontainers.image.source"="https://github.com/JcDenis/docker-dotclear"
LABEL "org.opencontainers.image.description"="Dotclear docker image $CNL_DOTCLEAR"
LABEL "org.opencontainers.image.licenses"="AGPL-3.0"

##
# Nginx
##

# Install required package
RUN apk add --no-cache --update \
    nginx \
    curl \
    tar \
    unzip \
    libxml2-utils
    #xq

# Create directories structure
RUN mkdir -p /var/www/dotclear \
    && chown -R www:www /var/lib/nginx /var/www

# Copy nginx configuration
COPY etc/nginx.conf /etc/nginx/nginx.conf
COPY etc/snippets_subfolder.conf /etc/nginx/snippets/snippets_subfolder.conf
COPY etc/snippets_subdomain.conf /etc/nginx/snippets/snippets_subdomain.conf
COPY etc/snippets_common.conf /etc/nginx/snippets/snippets_common.conf

# Fix vuln alpine 3.21.0 : curl 8.11.0-r2 => 8.11-r0
RUN apk upgrade curl

##
# PHP
##

# Try to bypass Alpine Linux iconv bug
#RUN apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/edge/community/ gnu-libiconv
RUN apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/v3.12/community/ gnu-libiconv=1.15-r2
ENV LD_PRELOAD=/usr/lib/preloadable_libiconv.so

# Use PHP 8.4 release
ENV VER_PHP=php84

# Install PHP required packages
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
    ${VER_PHP}-pgsql \
    ${VER_PHP}-opcache \
    ${VER_PHP}-dom \
    ${VER_PHP}-xml \
    ${VER_PHP}-simplexml \
    ${VER_PHP}-zip \
    ${VER_PHP}-pdo_sqlite

# Copy PHP configuration
COPY etc/${CNL_DOTCLEAR}-php.ini /etc/${VER_PHP}/php.ini
COPY etc/php-fpm.conf /etc/${VER_PHP}/php-fpm.d/www.conf

##
# Dotclear
##

# Download latest Dotclear version
RUN curl -fsSL -o versions.xml "http://download.dotclear.org/versions.xml" \
    && curl -fsSL -o dotclear.zip $(xmllint --xpath "//release[@name='$CNL_DOTCLEAR']/@href" versions.xml | awk -F'[="]' '!/>/{print $(NF-1)}') \
    && echo "$(xmllint --xpath "//release[@name='$CNL_DOTCLEAR']/@checksum" versions.xml | awk -F'[="]' '!/>/{print $(NF-1)}') dotclear.zip" | md5sum -c - \
    && mkdir -p /usr/src/dotclear \
    && unzip -d /usr/src dotclear.zip \
    && rm dotclear.zip

# Create predefined www structure
COPY www /var/lib/dotclear

# These variables are only used for first install, see inc/config.php, from dotclear 2.32
# Custom path for dotclear config file
ENV DC_RC_PATH=/var/www/dotclear/config.php
# Directory of third party plugins
ENV DC_PLUGINS_ROOT=/var/www/dotclear/plugins
# Directory for template cache files
ENV DC_TPL_CACHE=/var/www/dotclear/cache
# Directory for dotclear var
ENV DC_VAR=/var/www/dotclear/var

##
# Plugins
##

# DotclearWatch
ENV VER_PLUGIN_DW=0.9.3
RUN curl -fsSL -o plugin.zip "https://github.com/JcDenis/DotclearWatch/releases/download/v$VER_PLUGIN_DW/plugin-DotclearWatch.zip" \
    && mkdir -p /var/lib/dotclear/plugins/DotclearWatch \
    && unzip -d /var/lib/dotclear/plugins plugin.zip \
    && rm plugin.zip

# dcLog
ENV VER_PLUGIN_DL=1.7.3
RUN curl -fsSL -o plugin.zip "https://github.com/JcDenis/dcLog/releases/download/v$VER_PLUGIN_DL/plugin-dcLog.zip" \
    && mkdir -p /var/lib/dotclear/plugins/dcLog \
    && unzip -d /var/lib/dotclear/plugins plugin.zip \
    && rm plugin.zip

# sysInfo
ENV VER_PLUGIN_SI=10.3
RUN curl -fsSL -o plugin.zip "https://github.com/franck-paul/sysInfo/releases/download/$VER_PLUGIN_SI/plugin-sysInfo-$VER_PLUGIN_SI.zip" \
    && mkdir -p /var/lib/dotclear/plugins/sysInfo \
    && unzip -d /var/lib/dotclear/plugins plugin.zip \
    && rm plugin.zip

# Fix ownership
RUN chown -R www:www /var/lib/dotclear /usr/src/dotclear

##
# END
##

# Docker container uses port 80
EXPOSE 80

# Set working diretory for container starting script
WORKDIR /var/www/dotclear/app

# Add container starting script
ADD docker-entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/bin/sh", "/entrypoint.sh"]

# Docker container healthcheck
HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1:80/fpm-ping || exit 1