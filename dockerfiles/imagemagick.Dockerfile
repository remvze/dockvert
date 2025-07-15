FROM ubuntu:22.04

RUN apt-get update && apt-get install -y imagemagick

WORKDIR /data

ENTRYPOINT ["convert"]
