#!/usr/bin/env bash
set -e
HOST=$1
PORT=$2
COUNTER=15
if [ "$3" != "" ]; then COUNTER=$3; fi
out() { echo [`date`] $@; }
die() { echo "[`date`] ERROR ./wait_for_tcp: $@" >&2; exit 1; }

if ! [ "$HOST" ]; then die 'Expected host as first parameter'; fi
if ! [ "$PORT" ]; then die 'Expected port as second parameter'; fi

# before continuing, ensure TCP is reponding exists
out "Waiting for $HOST:$PORT... ($COUNTER)"
until nc -z $HOST $PORT
do
    COUNTER=$((COUNTER - 1))
    if [ "$COUNTER" == "0" ]; then
        die "$HOST waiting timeout. $HOST:$PORT was not ready."
    fi
    sleep 2
done

out "$HOST:$PORT is Ready"