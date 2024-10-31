#!/bin/bash

# docker-dotclear:latest

set -e

# Check if Dotclear exists
if ! [ -e index.php -a -e src/App.php ]; then
	# First installation
	echo >&2 "Dotclear not found in $(pwd) - copying now..."
	if [ "$(ls -A)" ]; then
		echo >&2 "WARNING: $(pwd) is not empty - press Ctrl+C now if this is an error!"
		( set -x; ls -A; sleep 10 )
	fi
	tar cf - --one-file-system -C /usr/src/dotclear . | tar xf -
	echo >&2 "Complete! Dotclear has been successfully copied to $(pwd)"
else
	echo >&2 "Dotclear found in $(pwd), checking upgrade..."
	# Check if Dotclear needs upgrade
	DOTCLEAR_CURRENT_VERSION=$(sed -n "s/^\s*\"release_version\":\s*\"\(.*\)\",/\1/p" release.json)
	if [ "$DOTCLEAR_CURRENT_VERSION" != "$DOTCLEAR_VERSION" ]; then
		echo >&2 "Upgrading Dotclear files from ${DOTCLEAR_CURRENT_VERSION} to ${DOTCLEAR_VERSION}, please wait..."
		tar cf - --one-file-system -C /usr/src/dotclear . | tar xf -
		echo >&2 "Complete! Dotclear files have been successfully upgraded to ${DOTCLEAR_VERSION}"
	else
		echo >&2 "No need to upgrade Dotclear ${DOTCLEAR_VERSION}"
	fi
fi

# Permissions
chown -R www-data:www-data /var/www/html

# Summary
echo >&2 "Starting services..."
echo >&2 "Debian $(cat /etc/debian_version)"
echo >&2 "$(nginx -v)PHP: $(php -r "echo PHP_VERSION;")"
echo >&2 "Dotclear: ${DOTCLEAR_VERSION}"

# Start services (in right order)
php-fpm -D
nginx -g 'daemon off;'

exec "$@"