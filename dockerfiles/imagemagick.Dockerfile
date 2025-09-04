FROM alpine:latest

RUN apk add --no-cache imagemagick

WORKDIR /data

ENTRYPOINT ["magick"]
