#!/bin/sh
set -eu

IMAGE_NAME=cyborghosting/srcds

docker build . --pull \
  --build-arg=CACHEBUST="$(date '+%s.%N')" \
  --tag="$IMAGE_NAME"
