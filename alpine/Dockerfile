# Pull base image
FROM alpine:latest
MAINTAINER Cdoco <ocdoco@gmail.com>

# Install bash
RUN set -x \
    && apk --update add bash gcc wget make tar \
    && rm -rf /var/cache/apk/* \
    && mkdir /opt/data \
    && mkdir /opt/source
    
