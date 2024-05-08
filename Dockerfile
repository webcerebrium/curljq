FROM alpine:latest

RUN apk --update --no-cache add \
    netcat-openbsd jq curl ca-certificates bash bc coreutils && \
    rm -rf /var/lib/apt/lists/* 

ADD *.sh /bin/

VOLUME /curl/output
