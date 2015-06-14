FROM node

RUN apt-get update
RUN apt-get install -y libpcap-dev xvfb libgtk2.0-0 libgconf-2-4 libnss3 libasound2 libxtst6

RUN npm install -g gulp electron-prebuilt node-gyp

ADD . /etc/dripcap
WORKDIR /etc/dripcap

RUN rm -rf .build node_modules
RUN npm install

RUN apt-get install -y

ENV DISPLAY :99.0
RUN gulp test
RUN gulp
