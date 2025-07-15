FROM alpine:latest

RUN apk add --no-cache p7zip

WORKDIR /data

ENTRYPOINT ["7z"]
