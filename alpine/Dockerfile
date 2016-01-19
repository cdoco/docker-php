# Pull base image
FROM alpine:latest
MAINTAINER Cdoco <ocdoco@gmail.com>

# Install bash
RUN set -x \
    && apk --update add bash nginx \
    && rm -rf /var/cache/apk/* \
