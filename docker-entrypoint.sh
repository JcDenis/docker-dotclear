#!/bin/sh

# docker-dotclear:*
# Container starting script

set -e

# Read image version
if [ "$DC_DOCKER_CANAL" == "stable" ]; then
	# stable = x.xx.x => x.xx.x
	export COMPARE_HAYSTACK="s/^\s*\"release_version\":\s*\"\(.*\)\",/\1/p"
else
	# testing : x.xx.x-pxxxxxxxx.xxxx, unstable : x.xx.x-dev-rxxxxxxxx.xxxx => xxxxxxxx.xxxx.0
	export COMPARE_HAYSTACK="s/^\s*\"release_version\":\s*\"\(.*\)\(-p\|-r\)\(.*\)\",/\3.0/p"
fi
export COMPARE_IMAGE=$(sed -n "${COMPARE_HAYSTACK}" /usr/src/dotclear/release.json)
export VERSION_IMAGE=$(sed -n "s/^\s*\"release_version\":\s*\"\(.*\)\",/\1/p" /usr/src/dotclear/release.json)

# Simple versions comparison function that fits all releases
function version { echo "$@" | awk -F. '{ printf("%d%04d%03d\n", $1,$2,$3); }'; }

# Update Docker structure
echo >&2 "Updating Docker structure..."
mkdir -p /var/www/dotclear/app \
	/var/www/dotclear/blogs \
	/var/www/dotclear/blogs/default \
	/var/www/dotclear/cache \
	/var/www/dotclear/plugins \
	/var/www/dotclear/servers \
	/var/www/dotclear/themes \
	/var/www/dotclear/var
# Always replace image plugins
cp -rf /var/lib/dotclear/plugins/* /var/www/dotclear/plugins
# Copy nginx server conf only if not exists
cp -n /var/lib/dotclear/servers/subdomain.conf /var/www/dotclear/servers/
cp -n /var/lib/dotclear/servers/subfolder.conf /var/www/dotclear/servers/

# Check if Dotclear is already on system
if ! [ -e index.php -a -e src/App.php ]; then
	# First installation
	echo >&2 "Dotclear not found in $(pwd) - copying now..."
	if [ "$(ls -A)" ]; then
		echo >&2 "WARNING: $(pwd) is not empty - press Ctrl+C now if this is an error!"
		( set -x; ls -A; sleep 5 )
	fi
	echo >&2 "Copying Dotclear files..."
	#tar cf - --one-file-system -C /usr/src/dotclear . | tar xf -
	cp -rf /usr/src/dotclear/* /var/www/dotclear/app
	echo >&2 "Complete! Dotclear has been successfully copied to $(pwd)"
else
	# Check if Dotclear needs upgrade
	COMPARE_VOLUME=$(sed -n "${COMPARE_HAYSTACK}" release.json)
	VERSION_VOLUME=$(sed -n "s/^\s*\"release_version\":\s*\"\(.*\)\",/\1/p" release.json)
	echo >&2 "Dotclear ${VERSION_VOLUME} found in $(pwd), checking upgrade..."
	if [ $(version $COMPARE_IMAGE) -gt $(version $COMPARE_VOLUME) ]; then
		echo >&2 "Upgrading Dotclear files from ${VERSION_VOLUME} to ${VERSION_IMAGE}, please wait..."
		#tar cf - --one-file-system -C /usr/src/dotclear . | tar xf -
		cp -rf /usr/src/dotclear/* /var/www/dotclear/app
		echo >&2 "Complete! Dotclear files have been successfully upgraded to ${VERSION_IMAGE}"
	else
		echo >&2 "No need to upgrade Dotclear ${VERSION_IMAGE}"
	fi
fi

# Update Docker structure
echo >&2 "Updating Dotclear common themes..."
cp -rf /var/www/dotclear/app/themes/* /var/www/dotclear/themes

# DEBUG mode for non stable releases
if [ "$DC_DOCKER_CANAL" == "stable" ]; then
	echo >&2 "Disabling Dotclear DEBUG mode"
	sed -i -e "s/'DC_DEBUG', true/'DC_DEBUG', false/g" /var/www/dotclear/app/src/Core/Config.php
else
	echo >&2 "Enabling Dotclear DEBUG mode and DEV mode"
	sed -i -e "s/'DC_DEBUG', false/'DC_DEBUG', true/g" /var/www/dotclear/app/src/Core/Config.php
	sed -i -e "s/ elseif (DC_DEBUG/ if (DC_DEBUG/g" /var/www/dotclear/app/src/Core/Config.php
	sed -i -e "s/'DC_DEV', false/'DC_DEV', true/g" /var/www/dotclear/app/src/Core/Config.php
fi

# Various cleanup. Sorry not sorry.
## Remove template cache files
rm -Rf /var/www/dotclear/cache/*
## first version of docker-dotclear uses default.conf but next there are 2 config
rm -f /var/www/dotclear/servers/default.conf

# Fix www permissions
echo >&2 "Setting up permissions..."
chown -R www:www /var/www/dotclear
[ -e /var/www/dotclear/config.php ] && chmod 600 /var/www/dotclear/config.php
chmod 600 -R /var/www/dotclear/servers

# Print summary to docker logs
VERSION_INSTALLED=$(sed -n "s/^\s*\"release_version\":\s*\"\(.*\)\",/\1/p" release.json)
echo >&2 '┌──'
echo >&2 "│ Summary: "
echo >&2 "│ ◦ Alpine $(cat /etc/alpine-release)"
echo >&2 "│ ◦ Nginx $(nginx -v 2>&1 | sed 's/nginx version: nginx\///')"
echo >&2 "│ ◦ PHP $(php84 -r "echo PHP_VERSION;")"
echo >&2 "│ ◦ Dotclear ${VERSION_INSTALLED}"
echo >&2 '└──'

# Start web server
php-fpm84 -D # FPM must start first in daemon mode
nginx # Then nginx in no daemon mode

# Switch from user root to wwww
exec runuser -u www "$@"