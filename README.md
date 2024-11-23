# README

![Stable image version](https://img.shields.io/github/v/release/JcDenis/docker-dotclear)
![Docker image size](https://img.shields.io/docker/image-size/jcpd/docker-dotclear/latest)
![Stable image downloads](https://img.shields.io/docker/pulls/jcpd/docker-dotclear)

![Stable image build](https://github.com/JcDenis/docker-dotclear/actions/workflows/release_stable.yml/badge.svg) 
![Testing image build](https://github.com/JcDenis/docker-dotclear/actions/workflows/release_testing.yml/badge.svg) 
![Unstable image build](https://github.com/JcDenis/docker-dotclear/actions/workflows/release_unstable.yml/badge.svg) 

## THE SHORT WAY

In your futur server, with Docker compose installed, execute:

    curl -fsSL -o docker-compose.yaml https://raw.githubusercontent.com/JcDenis/docker-dotclear/refs/heads/master/docker-compose.yaml && docker-compose up -d

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

### TAGS

Docker image tag is based on __Alpine Linux OS, Nginx server and PHP-FPM language__. 
It is composed of Dotclear version or release type:

* x.x : A given Dotclear version (ex: 2.31.1)
* latest : The latest stable Dotclear release
* testing: The latest dev of Dotclear stable branch
* dev : A Dotclear unstable (nightly) release

### Builds

Clone this repository:

    git clone https://github.com/JcDenis/docker-dotclear.git

To build image from stable canal, from the Dokerfile path, execute:

    docker build -t dotclear:latest --build-arg CANAL=stable .

Or to build image from testing canal, from the Dokerfile path, execute:

    docker build -t dotclear:testing --build-arg CANAL=testing .

Or to build image from unstable canal, from the Dokerfile path, execute:

    docker build -t dotclear:dev --build-arg CANAL=unstable .

Builds should support:

* postgresql and mysql and sqlite database
* linux/386 and linux/amd64 and linux/arm/V6 plateforms
* docker container healthcheck

### DOCKER

**Exemple of a docker compose file with a mariadb database:**

    services:
      # MYSQL database service
      dc_db:
        image: mariadb:latest
        container_name: dotcleardb
        restart: unless-stopped
        command: --transaction-isolation=READ-COMMITTED --log-bin=binlog --binlog-format=ROW
        volumes:
          - dc_db:/var/lib/mysql
        environment:
          MYSQL_ROOT_PASSWORD: dotclear_root
          MYSQL_DATABASE: dotclear_db
          MYSQL_USER: dotclear_user
          MYSQL_PASSWORD: dotclear_pwd
        healthcheck:
          test: ["CMD", "healthcheck.sh", "--connect", "--innodb_initialized"]
          start_period: 10s
          interval: 10s
          timeout: 5s
          retries: 3
    
      # PHP-FPM Service
      dc_app:
        image: jcpd/docker-dotclear:latest
        container_name: dotclearphp
        restart: unless-stopped
        volumes:
          - dc_app:/var/www/dotclear
        ports:
          - 80:80
        depends_on:
          dc_db: # MYSQL database service
            condition: service_healthy # Waiting for database ready
        environment:
          # These variables are only used for first install, see inc/config.php
          DC_DBDRIVER: mysqlimb4 # MYSQL full UTF-8
          DC_DBHOST: dc_db # MYSQL database service
          DC_DBNAME: dotclear_db # MYSQL_DATABASE
          DC_DBUSER: dotclear_user # MYSQL_USER 
          DC_DBPASSWORD: dotclear_pwd # MYSQL_PASSWORD 
          DC_DBPREFIX: dc_ # Database tables prefix
          DC_ADMINMAILFROM: contact@exemple.com # Dotclear mail from
    
    volumes:
      dc_app: # NGINX (dotclear) volume
      dc_db: # MYSQL (database) volume

 * You __MUST__ replace database USER and PASSWORD by something else.

Then execute:

    docker-compose up -d

Dotclear is now available on your server host at http://locahost/
On first run Dotclear does its installation process and ask you to create a first user.
On first run you should wait that container download and install required version of Dotclear,
this may takes a while...

**Another exemple with an SQLite database and a single container:**

    services:
      dotclear:
        image: jcpd/docker-dotclear:latest
        container_name: dotclear
        restart: unless-stopped
        volumes:
          - ./dotclear:/var/www/dotclear
        ports:
          - 80:80
        environment:
          DC_DBDRIVER: sqlite
          DC_DBNAME: \var\www\dotclear\sqlite.db
          DC_ADMINMAILFROM: contact@exemple.com

or with a simple docker command:

    docker run -d --name dotclear -p 80:80 -v dotclear:/var/www/dotclear -e DC_DBDRIVER=sqlite -e DC_DBNAME=/var/www/dotclear/sqlite.db -e DC_ADMINMAILFROM=contact@exemple.com jcpd/docker-dotclear:latest

SQLite database will be stored in folder \var\www\dotclear

### BLOG

__Standard configuration by subfolders__

These images use Dotclear URL rewriting in PATH INFO mode.
By default URL and path should be corrected by a custom plugin automatically.
Blogs URLs looks like:

 * http://localhost/default/
 * http://localhost/blog2/
 * ...

Blogs administration is available at http://localhost/admin

When you create a new blog in this configuration,
you must use the _blog_id_ with the trailing slash in blog URL setting like http://localhost/blog_id/

__Standard configuration by subdomains__

These images use Dotclear URL rewriting in PATH INFO mode.
By default URL and path should be corrected by a custom plugin automatically.
Blogs URLs looks like:

 * http://default.domain.tld/
 * http://blog2.domain.tld/
 * ...

Blogs administration is available at http://xxx.domain.tld/admin

When you create a new blog in this configuration,
you must use the _blog_id_ as subdomain in blog URL setting like http://blog_id.domain.tld/

__Non standard configuration__

Setup nginx server configuration (see bellow):

 * adapt _/var/www/dotclear/servers/*.conf_ to your needs
 
Then to configure blog:

 * go to the administration interface at http://my_custom_domain/admin,
 * left side menu _Blog settings_
 * panel _Advanced parameters_
 * set _Blog URL_ to http://my_custom_domain/ (with trailing slash)
 * set _URL scan method_ to 'PATH_INFO'

Then fix public_path and public_url for the blog:

 * go to the administration interface at http://my_custom_domain/admin,
 * left side menu _about:config_
 * panel _system_
 * set _public_path_ to the real path on system to public directory of the blog
 * set _public_url_ to the URL of the public directory of the blog

### STRUCTURE

Default root path of this image structure is in __/var/www/dotclear__ with sub folders:

 * _app_ : Dotclear application files
 * _blogs_ : Blogs public directories
 * _cache_ : Dotclear template cache
 * _plugins_ : Third party plugins directory
 * _servers_ : Nginx servers configurations
 * _themes_ : Dotclear themes directory
 * _var_ : Dotclear var directory

### UPGRADE

To upgrade Dotclear to next version,
it is recommanded to pull latest image and restart the docker container
or use Dotclear buitin update system but themes wiil not be updated.

### TODO

* Add better cache management. From another container or from Dotclear container.
* Add mail support.

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
