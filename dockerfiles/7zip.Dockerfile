FROM ubuntu:22.04

RUN apt-get update && apt-get install -y p7zip-full

WORKDIR /data

ENTRYPOINT ["7z"]
