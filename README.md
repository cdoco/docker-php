## PHP 7.0.8

[![Build Status](https://travis-ci.org/cdoco/docker-php.svg)](https://travis-ci.org/cdoco/docker-php)

* Centos 7
* Nginx 1.9.9
* PHP 7.0.8

## Install Docker
* ubuntu: `sudo apt-get install docker.io`
* centos: `sudo yum install docker`

## Usage
* clone this repo: `git clone phttps://github.com/cdoco/docker-php`
* cd in: `cd docker-php`
* build it: `docker build -t php ./`
* run it: `docker run --name some-php -d -p 8090:80 php`

## Volume local project directory
* volume local directory: `docker run --name some-php -v /some/content:/opt/source/www:ro -d -p 8090:80 php`

## Edit the configuration file for PHP or nginx
* you can modify the configuration file in the files directory.
