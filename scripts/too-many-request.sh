#!/bin/bash

set -eu

URL=${1:-}
NUM=${2:-120}

if [ -z ${URL} ]; then
  echo 'please set the "URL" argument and try again.' >&2
  exit 1
fi

for i in $(seq 0 ${NUM})
do
  echo "[request ${i}]"
  curl "${URL}"
  echo "---"
  sleep 0.1
done
