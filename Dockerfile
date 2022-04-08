FROM alpine:3.15

RUN apk --update --no-cache add \
    netcat-openbsd jq curl ca-certificates bash bc && \
    rm -rf /var/lib/apt/lists/* 

ADD *.sh /bin/

VOLUME /curl/output
