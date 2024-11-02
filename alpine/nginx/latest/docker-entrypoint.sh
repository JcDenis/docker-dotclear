#!/bin/sh

# docker-dotclear:latest

set -e

# Check if Dotclear exists
if ! [ -e index.php -a -e src/App.php ]; then
	# First installation
	echo >&2 "Dotclear not found in $(pwd) - copying now..."
	if [ "$(ls -A)" ]; then
		echo >&2 "WARNING: $(pwd) is not empty - press Ctrl+C now if this is an error!"
		( set -x; ls -A; sleep 5 )
	fi
	echo >&2 "Copying Dotclear files..."
	tar cf - --one-file-system -C /usr/src/dotclear . | tar xf -
	echo >&2 "Complete! Dotclear has been successfully copied to $(pwd)"
else
	echo >&2 "Dotclear found in $(pwd), checking upgrade..."
	# Check if Dotclear needs upgrade
	VER_CURRENT=$(sed -n "s/^\s*\"release_version\":\s*\"\(.*\)\",/\1/p" release.json)
	if [ "$VER_CURRENT" != "$VER_DOTCLEAR" ]; then
		echo >&2 "Upgrading Dotclear files from ${VER_CURRENT} to ${VER_DOTCLEAR}, please wait..."
		tar cf - --one-file-system -C /usr/src/dotclear . | tar xf -
		echo >&2 "Complete! Dotclear files have been successfully upgraded to ${VER_DOTCLEAR}"
	else
		echo >&2 "No need to upgrade Dotclear ${VER_DOTCLEAR}"
	fi
fi

# Permissions
echo >&2 "Setting up permissions..."
chown -R www:www /var/www/html

# Summary
echo >&2 "Alpine $(cat /etc/alpine-release)"
echo >&2 "$(nginx -v)PHP $(php -r "echo PHP_VERSION;")"
echo >&2 "Dotclear: ${VER_DOTCLEAR}"

php-fpm83 -D # FPM must start first in daemon mode
nginx # Then nginx in no daemon mode

exec "$@"