#!/usr/bin/env bash
set -e

export status=$1
export service_name=$2
export http_addr=$3
out() { echo [`date`] $@; }
die() { echo "[`date`] ERROR ./wait_for_status: $@" >&2; exit 1; }

if ! [ "$status" ]; then die "Expected status"; fi
if ! [ "$service_name" ]; then die "Expected service_name"; fi
if ! [ "$http_addr" ]; then die "Expected http_addr"; fi

let COUNTER=12
while [[ "$(curl -s -o /dev/null -w '%{http_code}' $http_addr)" != "$status" ]]; do
   out "Waiting for $service_name at $http_addr... ($COUNTER)"
   COUNTER=$((COUNTER - 1))
   if [ "$COUNTER" == "0" ]; then die "$service_name NOT STARTED"; fi
   sleep 5
done

out "$http_addr is available"