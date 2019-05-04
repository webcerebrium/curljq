# curljq
Curl + JQ + NetCat Dockerfile

### Purpose

The purpose of this docker image is to contain minimal set of tools
for integration testing of dockerized web services: cURL, jq (JSON parsing), bc (hex parsing), netcat and bash shell.

### Usage:

Example of usage in `docker-compose.yml`:
```
services:
  client:
    build: wcrbrm/curljq
    volumes:
      - ./var/output:/curl/output
```

### License
MIT