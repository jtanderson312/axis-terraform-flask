# base image
FROM node:alpine

# set working directory
WORKDIR /usr/src/app

RUN apk add --no-cache --virtual .gyp python make g++

# add `/usr/src/app/node_modules/.bin` to $PATH
ENV PATH /usr/src/app/node_modules/.bin:$PATH

# install and cache app dependencies
COPY package.json /usr/src/app/package.json
COPY yarn.lock  /usr/src/app/yarn.lock

RUN yarn

CMD ["yarn", "start"]