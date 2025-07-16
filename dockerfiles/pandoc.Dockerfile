FROM pandoc/latex:3.1

WORKDIR /data

ENTRYPOINT ["pandoc"]
