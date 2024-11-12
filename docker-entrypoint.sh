#!/bin/sh

# docker-dotclear:*
# Container starting script

set -e

# Read image version
export VER_DOTCLEAR=$(sed -n "s/^\s*\"release_version\":\s*\"\(.*\)\",/\1/p" /usr/src/dotclear/release.json)

# Simple versions comparison function that works with Dotclear versioning
function version { echo "$@" | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }'; }

# Check if Dotclear is already on system
if ! [ -e index.php -a -e src/App.php ]; then
	# First installation
	echo >&2 "Dotclear not found in $(pwd) - copying now..."
	if [ "$(ls -A)" ]; then
		echo >&2 "WARNING: $(pwd) is not empty - press Ctrl+C now if this is an error!"
		( set -x; ls -A; sleep 5 )
	fi
	echo >&2 "Copying Dotclear structure..."
	cp -R /var/lib/dotclear /var/www
	echo >&2 "Copying Dotclear files..."
	tar cf - --one-file-system -C /usr/src/dotclear . | tar xf -
	echo >&2 "Complete! Dotclear has been successfully copied to $(pwd)"
else
	echo >&2 "Dotclear found in $(pwd), checking upgrade..."
	# Check if Dotclear needs upgrade
	VER_CURRENT=$(sed -n "s/^\s*\"release_version\":\s*\"\(.*\)\",/\1/p" release.json)
	if [ $(version $VER_DOTCLEAR) -gt $(version $VER_CURRENT) ]; then
		echo >&2 "Upgrading Dotclear files from ${VER_CURRENT} to ${VER_DOTCLEAR}, please wait..."
		tar cf - --one-file-system -C /usr/src/dotclear . | tar xf -
		echo >&2 "Complete! Dotclear files have been successfully upgraded to ${VER_DOTCLEAR}"
	else
		echo >&2 "No need to upgrade Dotclear ${VER_DOTCLEAR}"
	fi
fi

# DEBUG mode for unstable release
if [ "$CNL_DOTCLEAR" == "unstable" ]; then
	echo >&2 "Enabling Dotclear DEBUG mode"
	sed -i -e "s/ \/\*== DC_DEBUG ==/ \/\/\*== DC_DEBUG ==/g" /var/www/dotclear/app/src/Config.php
else
	echo >&2 "Disabling Dotclear DEBUG mode"
	sed -i -e "s/ \/\/\*== DC_DEBUG ==/ \/\*== DC_DEBUG ==/g" /var/www/dotclear/app/src/Config.php
fi

# Fix www permissions
echo >&2 "Setting up permissions..."
chown -R www:www /var/www/dotclear

# Print summary to docker logs
echo >&2 "Alpine $(cat /etc/alpine-release)"
echo >&2 "$(nginx -v)PHP $(php -r "echo PHP_VERSION;")"
echo >&2 "Dotclear: ${VER_DOTCLEAR}"

# Start web server
php-fpm83 -D # FPM must start first in daemon mode
nginx # Then nginx in no daemon mode

exec "$@"