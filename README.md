# README

## WHAT IS DOTCLEAR

Dotclear is an open-source web publishing software.
Take control over your blog!

Dotclear project's purpose is to provide a user-friendly
tool allowing anyone to publish on the web, regardless of their technical skills.

=> https://dotclear.org/

## WHAT IS DOCKER-DOTCLEAR

This repository contains all features to build or run Dotclear on a Docker environment.
It is hightly based on work from [darknao](https://github.com/darknao/docker-dotclear).

* Dotclear docker images are avaialable at [Docker hub](https://hub.docker.com/r/jcpd/docker-dotclear)
* Dotclear docker sources are avaialable at [Github repository](https://github.com/JcDenis/docker-dotclear)

__Important notes:__
As of today, current images structure change on every release, 
do not use these images in production environment.
One of possible breaking change in futur could be the support of multi-blogs 
with changed in docker volumes and system path.

### TAGS

dotclear_version-server_type

* jcpd/docker-dotclear:latest is base on stable Alpine / Nginx / PHP-FPM
* jcpd/docker-dotclear:x.xx-dnf is based on stable Debian / Nginx / PHP-FPM
* jcpd/docker-dotclear:x.xx-anf is based on stable Alpine / Nginx / PHP-FPM
* ... (next to come)

### DOCKER

Exemple of a docker compose file with a mariadb database.

    services:

      # MYSQL database service
      dc_db:
        image: mariadb:latest
        container_name: dotcleardb
        restart: always
        command: --transaction-isolation=READ-COMMITTED --log-bin=binlog --binlog-format=ROW
        volumes:
          - dc_db:/var/lib/mysql
        environment:
          MYSQL_ROOT_PASSWORD: dotclear_root
          MYSQL_DATABASE: dotclear_db
          MYSQL_USER: dotclear_user
          MYSQL_PASSWORD: dotclear_pwd
    
      # PHP-FPM Service
      dc_app:
        image: jcpd/docker-dotclear:latest
        container_name: dotclearphp
        volumes:
          - dc_app:/var/www/html
          - dc_plugins:/var/www/html/other_plugins
        ports:
          - 8080:80
        depends_on:
          - dc_db # MYSQL database service
        environment:
          # These variables are only used for first install, see inc/config.php, from dotclear 2.32
          DC_DBDRIVER: mysqlimb4 # MYSQL full UTF-8
          DC_DBHOST: dc_db # MYSQL database service
          DC_DBNAME: dotclear_db # MYSQL_DATABASE
          DC_DBUSER: dotclear_user # MYSQL_USER 
          DC_DBPASSWORD: dotclear_pwd # MYSQL_PASSWORD 
          DC_DBPREFIX: dc_ # Database tables prefix
          DC_ADMINMAILFROM: contact@exemple.com # Dotclear mail from
          # Optionnal path for third party plugins, must be in /var/www/html
          DC_PLUGINS_ROOT: /var/www/html/other_plugins
    
    volumes:
      dc_app: # NGINX volume
      dc_plugins: # plugins volume
      dc_db: # MYSQL volume

* You __must__ replace database USER and PASSWORD by something else.

Then execute 

    docker-compose up -d

Dotclear is now available on your server host at http://locahost:8080/

Before Dotclear 2.32, on first run, Dotclear does installation process, you must provide values of :
* MySQl database container service name as database host (here dc_db)
* MYSQL_DATABASE as database name
* MYSQL_USER as database login
* MYSQL_PASSWORD as database password

Builds should support postgresql and mysql database.

On first run you should wait that container download ans install required version of Dotclear...

### BLOG

These images support Dotclear URL rewriting in PATH INFO mode.
To configure default blog, go to the administration interface at http://localhost/admin,
 * left side menu _Blog settings_
 * panel _Advanced parameters_
 * set _Blog URL_ to http://localhost/ (with trailing slash)
 * set _URL scan method_ to 'PATH_INFO'

### TODO

* Disable upgrade from Dotclear. Should only use upgrade from container restart ?
* or Fix downgrade on container restart when Dotclear has been upgraded from UI.
* Use auto installation from container environment variables.
* Add support of Dotclear's DEBUG mode for Dotclear and logs.
* Add better cache management. From another container or from Dotclear container.
* Add mail support.
* Enhance server and php configuration. From x.conf files.
* Add builds from Alpine and Apache and maybe without FPM.

### CONTRIBUTING

This image is an open source project. If you'd like to contribute, please read the [CONTRIBUTING file](/CONTRIBUTING.md).
You can submit a pull request, or feel free to use any other way you'd prefer.

### LICENSE

Copyright Jean-Christian Paul Denis
AGPL-v3 <https://www.gnu.org/licenses/agpl-3.0.html>

This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Affero General Public License for more details.
You should have received a copy of the GNU Affero General Public License along with this program.  If not, see <https://www.gnu.org/licenses/>.

Dotclear software is licensed under AGPL-3, Copyright Olivier Meunier & Association Dotclear
