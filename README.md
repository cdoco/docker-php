## PHP 7.0.8

[![Build Status](https://travis-ci.org/cdoco/docker.svg)](https://travis-ci.org/cdoco/docker)

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
* run it: `docker run -d -p 8090:80 php`
