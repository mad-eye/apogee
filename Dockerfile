FROM node:0.10.40
MAINTAINER Mike Risse

ENV PORT 3000

RUN apt-get update
RUN curl https://install.meteor.com | /bin/sh

RUN npm install -g meteorite

ADD .meteor /app/.meteor
WORKDIR /app
# HACK: Need to install meteor and cache it.  Sadly, `meteor --help` does this.
RUN meteor --help

ADD . /app
RUN mrt install

RUN meteor bundle /app.tar.gz
RUN mkdir -p /build
WORKDIR /build
RUN tar zxf /app.tar.gz
RUN rm -r /build/bundle/programs/server/node_modules/fibers
RUN cd /build/bundle/programs/server && npm install fibers@1.0.1
CMD node /build/bundle/main.js
WORKDIR /app

