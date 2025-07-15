FROM pandoc/core:3.1

WORKDIR /data

ENTRYPOINT ["pandoc"]
