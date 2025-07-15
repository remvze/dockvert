FROM jrottenberg/ffmpeg:4.4-alpine

WORKDIR /data

ENTRYPOINT ["ffmpeg"]
