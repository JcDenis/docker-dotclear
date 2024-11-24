#!/bin/sh

# docker-dotclear:*
# Container starting script

set -e

# Read image version
export VER_DOTCLEAR=$(sed -n "s/^\s*\"release_version\":\s*\"\(.*\)\",/\1/p" /usr/src/dotclear/release.json)

# Simple versions comparison function that works with Dotclear stable versioning
function version { echo "$@" | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }'; }

# Update Docker structure
echo >&2 "Updating Docker structure..."
cp -Ru /var/lib/dotclear /var/www

# Check if Dotclear is already on system
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
	if [ $(version $VER_DOTCLEAR) -gt $(version $VER_CURRENT) ]; then
		echo >&2 "Upgrading Dotclear files from ${VER_CURRENT} to ${VER_DOTCLEAR}, please wait..."
		tar cf - --one-file-system -C /usr/src/dotclear . | tar xf -
		echo >&2 "Complete! Dotclear files have been successfully upgraded to ${VER_DOTCLEAR}"
	else
		echo >&2 "No need to upgrade Dotclear ${VER_DOTCLEAR}"
	fi
fi

# Update Docker structure
echo >&2 "Updating Dotclear common themes..."
cp -Ru /var/www/dotclear/app/themes/* /var/www/dotclear/themes

# DEBUG mode for non stable releases
if [ "$CNL_DOTCLEAR" == "stable" ]; then
	echo >&2 "Disabling Dotclear DEBUG mode"
	sed -i -e "s/ \/\/\*== DC_DEBUG ==/ \/\*== DC_DEBUG ==/g" /var/www/dotclear/app/src/Config.php
else
	echo >&2 "Enabling Dotclear DEBUG mode"
	sed -i -e "s/ \/\*== DC_DEBUG ==/ \/\/\*== DC_DEBUG ==/g" /var/www/dotclear/app/src/Config.php
fi

# Various cleanup. Sorry not sorry.
## Remove template cache files
rm -Rf /var/www/dotclear/cache/*
## first version of docker-dotclear uses default.conf but next there are 2 config
rm -f /var/www/dotclear/servers/default.conf

# Fix www permissions
echo >&2 "Setting up permissions..."
chown -R www:www /var/www/dotclear

# Print summary to docker logs
echo >&2 "| Summary: "
echo >&2 "| Alpine $(cat /etc/alpine-release)"
echo >&2 "| Nginx $(nginx -v 2>&1 | sed 's/nginx version: nginx\///')"
echo >&2 "| PHP $(php -r "echo PHP_VERSION;")"
echo >&2 "| Dotclear ${VER_DOTCLEAR}"

# Start web server
php-fpm83 -D # FPM must start first in daemon mode
nginx # Then nginx in no daemon mode

exec "$@"