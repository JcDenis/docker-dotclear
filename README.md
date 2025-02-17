# README

![Stable image version](https://img.shields.io/docker/v/jcpd/docker-dotclear?sort=semver)
![Docker image size](https://img.shields.io/docker/image-size/jcpd/docker-dotclear/latest)
![Stable image downloads](https://img.shields.io/docker/pulls/jcpd/docker-dotclear)

![Stable image build](https://github.com/JcDenis/docker-dotclear/actions/workflows/release_stable.yml/badge.svg) 
![Testing image build](https://github.com/JcDenis/docker-dotclear/actions/workflows/release_testing.yml/badge.svg) 
![Unstable image build](https://github.com/JcDenis/docker-dotclear/actions/workflows/release_unstable.yml/badge.svg) 


## 1. THE SHORT WAY

In your futur server, with Docker installed, execute:

    docker run -d --name dotclear -p 80:80 -v dotclear:/var/www/dotclear jcpd/docker-dotclear

or with Docker compose installed, execute:

    curl -fsSL -o docker-compose.yaml https://raw.githubusercontent.com/JcDenis/docker-dotclear/refs/heads/master/docker-compose.yaml && docker-compose up -d



## 2. WHAT IS DOTCLEAR

Dotclear is an open-source web publishing software.
Take control over your blog!

Dotclear project's purpose is to provide a user-friendly
tool allowing anyone to publish on the web, regardless of their technical skills.

=> https://dotclear.org/


## 3. WHAT IS DOCKER-DOTCLEAR

This repository contains all features to build or run Dotclear on a Docker environment.
It is hightly based on work from [darknao](https://github.com/darknao/docker-dotclear).

* Dotclear docker images are available at [Docker hub](https://hub.docker.com/r/jcpd/docker-dotclear) or [Github registry](https://github.com/JcDenis/docker-dotclear/pkgs/container/docker-dotclear)
* Dotclear docker sources are available at [Github repository](https://github.com/JcDenis/docker-dotclear)
* Dotclear docker helps (french) are available at [Doclear Watch Blog](https://docker.dotclear.watch)


### 3.1 TAGS

Docker images are based on __Alpine Linux OS, Nginx server and PHP-FPM language__. 
Image tags are composed of Dotclear version or release type:

* x.x : A given Dotclear version (ex: 2.31.1)
* latest : The latest stable Dotclear release
* testing: The latest dev of Dotclear stable branch
* dev : A Dotclear unstable (nightly) release


### 3.2 BUILDS

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
* linux/386,linux/amd64,linux/arm/v6,linux/arm/v7,linux/arm64/v8,linux/ppc64le,linux/s390x (and more) plateforms
* docker container healthcheck


### 3.3 DOCKER

#### 3.3.1 Exemple of a docker compose file with a mariadb database

Create and edit a **docker-compose.yaml** file and put into it this contents :

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


#### 3.3.2 Exemple of a docker compose file with an SQLite database and a single container

Create and edit a **docker-compose.yaml** file and put into it this contents :

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

Then execute:

    docker-compose up -d


#### 3.3.3 Direct docker run without docker compose

Exemple with a simple docker command :

    docker run -d --name dotclear -p 80:80 -v dotclear:/var/www/dotclear -e DC_DBDRIVER=sqlite -e DC_DBNAME=/var/www/dotclear/sqlite.db -e DC_ADMINMAILFROM=contact@exemple.com jcpd/docker-dotclear:latest

SQLite database will be stored in folder \var\www\dotclear


### 3.4 BLOG


#### 3.4.1 Standard configuration by subfolders

These images use Dotclear URL rewriting in PATH INFO mode.
By default URL and path should be corrected by a custom plugin automatically.
Blogs URLs looks like:

 * http://localhost/default/
 * http://localhost/blog2/
 * ...

Blogs administration is available at http://localhost/admin

When you create a new blog in this configuration,
you must use the _blog_id_ with the trailing slash in blog URL setting like http://localhost/blog_id/

__Web server configuration__

To customized web server configuration for subfolders, edit:

> /var/www/dotclear/app/servers/subfolder.conf

Original contents looks like:

    server {
        server_name localhost;
        include /etc/nginx/snippets/snippets_subfolder.conf;
        include /etc/nginx/snippets/snippets_common.conf;
    }


#### 3.4.2 Standard configuration by subdomains

These images use Dotclear URL rewriting in PATH INFO mode.
By default URL and path should be corrected by a custom plugin automatically.
Blogs URLs looks like:

 * http://default.domain.tld/
 * http://blog2.domain.tld/
 * ...

Blogs administration is available at http://xxx.domain.tld/admin

When you create a new blog in this configuration,
you must use the _blog_id_ as subdomain in blog URL setting like http://blog_id.domain.tld/

__Web server configuration__

To customized web server configuration for subdomains, edit:

> /var/www/dotclear/app/servers/subdomain.conf

Original contents looks like:

    server {
        server_name ~^(?<dc_blog_id>\w*?)?\.?(\w+\.\w+)$;
        if ($dc_blog_id = '') {
                set $dc_blog_id default;
        }
        if ($dc_blog_id = 'blog') {
                set $dc_blog_id default;
        }
        include /etc/nginx/snippets/snippets_subdomain.conf;
        include /etc/nginx/snippets/snippets_common.conf;
    }


#### 3.4.3 Non standard configuration

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


### 3.5 STRUCTURE

Default root path of this image structure is in __/var/www/dotclear__ with sub folders:

 * _app_ : Dotclear application files
 * _blogs_ : Blogs public directories
 * _cache_ : Dotclear template cache
 * _plugins_ : Third party plugins directory
 * _servers_ : Nginx servers configurations
 * _themes_ : Dotclear themes directory
 * _var_ : Dotclear var directory


### 3.6 UPGRADE

To upgrade Dotclear to next version it is recommanded to pull latest image and restart the docker container:

    docker pull jcpd/docker-dotclear:latest && docker compose up -d

or use Dotclear buitin update system but themes wiil not be updated.


## 4. TODO

* Add better cache management. From another container or from Dotclear container.
* Add mail support.


## 5. SECURITY

* Nginx master process runs as root and set uid/gid to user www
* PHP-FPM master process runs as root and set uid/gid to user www
* Docker image entrypoint runs as root and set runuser to www at its end
* Dotclear application files are chown to user www

For security report see [SECURITY file](/SECURITY.md) or open a ticket on github repository.


## 6. CONTRIBUTING

This image is an open source project. If you'd like to contribute, please read the [CONTRIBUTING file](/CONTRIBUTING.md).
You can submit a pull request, or feel free to use any other way you'd prefer.


## 7. LICENSES

Many licenses are involved in there, from files in repository to those from softwares used in final Docker image.


### 7.1 DOCKER-DOTCLEAR REPOSITORY FILES

All files in docker-dotclear repository are licensed under AGPL-3, Copyright (c) Jean-Christian Paul Denis.

    Copyright (c) Jean-Christian Paul Denis
    AGPL-v3 <https://www.gnu.org/licenses/agpl-3.0.html>
    This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Affero General Public License for more details.
    You should have received a copy of the GNU Affero General Public License along with this program.  If not, see <https://www.gnu.org/licenses/>.


### 7.2 LINUX ALPINE

Linux Alpine operating system in these final Docker images is licensed under MIT License, Copyright (c) 2019 Natanael Copa.


### 7.3 NGINX

NGINX web server in these final Docker images is licensed under 2-clause BSD-like license, Copyright (c) 2002-2021 Igor Sysoev, 2011-2024 Nginx, Inc.


### 7.4 PHP

PHP hypertext preprocessor in these final Docker images is licensed under the PHP License v3.01, copyright (c) the PHP Group.


### 7.5 DOTCLEAR

Dotclear software present in these final Docker images is licensed under AGPL-v3, Copyright (c) Olivier Meunier & Association Dotclear.
