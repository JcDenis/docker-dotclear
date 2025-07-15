# docker-dotclear:*
# docker-dotclear Dockerfile

##
# Alpine
##

# Use fix Alpine docker release
FROM alpine:3.21.3

# Select Dotclear release canal (stable | unstable)
ARG CANAL stable

# Set environment variables
ENV DC_DOCKER_CANAL=$CANAL \
    DC_DOCKER_PHP=php84 \
    DC_DOCKER_PLUGIN_DOTCLEARWATCH=1.0 \
    DC_DOCKER_PLUGIN_DCLOG=1.7.4 \
    DC_DOCKER_PLUGIN_SYSINFO=13.0 \
    DC_DOCKER_PLUGIN_TEMPLATEHELPER=1.8 \
    DC_RC_PATH=/var/www/dotclear/config.php \
    DC_PLUGINS_ROOT=/var/www/dotclear/plugins \
    DC_TPL_CACHE=/var/www/dotclear/cache \
    DC_VAR=/var/www/dotclear/var

# Image label
LABEL "org.opencontainers.image.authors"="Jean-Christian Paul Denis" \
    "org.opencontainers.image.source"="https://github.com/JcDenis/docker-dotclear" \
    "org.opencontainers.image.description"="Dotclear docker image $DC_DOCKER_CANAL" \
    "org.opencontainers.image.licenses"="AGPL-3.0"

# Set system timezone
RUN echo "UTC" > /etc/timezone

# Create user
RUN adduser -D -g 'www' www


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

# Create directories structure
RUN mkdir -p /var/www/dotclear \
    && chown -R www:www /var/lib/nginx /var/www

# Copy nginx configuration
COPY etc/nginx.conf /etc/nginx/nginx.conf
COPY etc/snippets_subfolder.conf /etc/nginx/snippets/snippets_subfolder.conf
COPY etc/snippets_subdomain.conf /etc/nginx/snippets/snippets_subdomain.conf
COPY etc/snippets_common.conf /etc/nginx/snippets/snippets_common.conf

# Fix vuln alpine 3.21.2
RUN apk upgrade --no-cache --update openssl musl


##
# PHP
##

# Try to bypass Alpine Linux iconv bug
RUN apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/v3.12/community/ gnu-libiconv=1.15-r2
ENV LD_PRELOAD=/usr/lib/preloadable_libiconv.so

# Install PHP required packages
RUN apk add --no-cache --update \
    ${DC_DOCKER_PHP}-common \
    ${DC_DOCKER_PHP}-cli \
    ${DC_DOCKER_PHP}-fpm \
    ${DC_DOCKER_PHP}-session \
    ${DC_DOCKER_PHP}-curl \
    ${DC_DOCKER_PHP}-gd \
    ${DC_DOCKER_PHP}-gmp \
    ${DC_DOCKER_PHP}-exif \
    ${DC_DOCKER_PHP}-tidy \
    ${DC_DOCKER_PHP}-intl \
    ${DC_DOCKER_PHP}-json \
    ${DC_DOCKER_PHP}-mbstring \
    ${DC_DOCKER_PHP}-iconv \
    ${DC_DOCKER_PHP}-gettext \
    ${DC_DOCKER_PHP}-mysqli \
    ${DC_DOCKER_PHP}-pgsql \
    ${DC_DOCKER_PHP}-opcache \
    ${DC_DOCKER_PHP}-dom \
    ${DC_DOCKER_PHP}-xml \
    ${DC_DOCKER_PHP}-simplexml \
    ${DC_DOCKER_PHP}-zip \
    ${DC_DOCKER_PHP}-pdo_sqlite

# Copy PHP configuration
COPY etc/${DC_DOCKER_CANAL}-php.ini /etc/${DC_DOCKER_PHP}/php.ini
COPY etc/php-fpm.conf /etc/${DC_DOCKER_PHP}/php-fpm.d/www.conf


##
# Dotclear
##

# Download latest Dotclear version
RUN curl -fsSL -o versions.xml "http://download.dotclear.org/versions.xml" \
    && curl -fsSL -o dotclear.zip $(xmllint --xpath "//release[@name='$DC_DOCKER_CANAL']/@href" versions.xml | awk -F'[="]' '!/>/{print $(NF-1)}') \
    && echo "$(xmllint --xpath "//release[@name='$DC_DOCKER_CANAL']/@checksum" versions.xml | awk -F'[="]' '!/>/{print $(NF-1)}') dotclear.zip" | md5sum -c - \
    && mkdir -p /usr/src/dotclear \
    && unzip -d /usr/src dotclear.zip \
    && rm dotclear.zip

# Create predefined www structure
COPY www /var/lib/dotclear


##
# Plugins
##

# DotclearWatch
RUN curl -fsSL -o plugin.zip "https://github.com/JcDenis/DotclearWatch/releases/download/v$DC_DOCKER_PLUGIN_DOTCLEARWATCH/plugin-DotclearWatch.zip" \
    && mkdir -p /var/lib/dotclear/plugins/DotclearWatch \
    && unzip -d /var/lib/dotclear/plugins plugin.zip \
    && rm plugin.zip

# dcLog
RUN curl -fsSL -o plugin.zip "https://github.com/JcDenis/dcLog/releases/download/v$DC_DOCKER_PLUGIN_DCLOG/plugin-dcLog.zip" \
    && mkdir -p /var/lib/dotclear/plugins/dcLog \
    && unzip -d /var/lib/dotclear/plugins plugin.zip \
    && rm plugin.zip

# TemplateHelper
RUN curl -fsSL -o plugin.zip "https://github.com/franck-paul/TemplateHelper/releases/download/$DC_DOCKER_PLUGIN_TEMPLATEHELPER/plugin-TemplateHelper-$DC_DOCKER_PLUGIN_TEMPLATEHELPER.zip" \
    && mkdir -p /var/lib/dotclear/plugins/TemplateHelper \
    && unzip -d /var/lib/dotclear/plugins plugin.zip \
    && rm plugin.zip

# sysInfo
RUN curl -fsSL -o plugin.zip "https://github.com/franck-paul/sysInfo/releases/download/$DC_DOCKER_PLUGIN_SYSINFO/plugin-sysInfo-$DC_DOCKER_PLUGIN_SYSINFO.zip" \
    && mkdir -p /var/lib/dotclear/plugins/sysInfo \
    && unzip -d /var/lib/dotclear/plugins plugin.zip \
    && rm plugin.zip

##
# END
##

# Fix ownership
RUN chown -R www:www /var/lib/dotclear /usr/src/dotclear

# Docker container uses port 80
EXPOSE 80

# Set working diretory for container starting script
WORKDIR /var/www/dotclear/app

# Add container starting script
ADD docker-entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/bin/sh", "/entrypoint.sh"]

# Docker container healthcheck
HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1:80/fpm-ping || exit 1