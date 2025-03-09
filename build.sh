#!/bin/sh

DOCKERHUB_TAG=cyborghosting/steamcmd

set -eu

#docker build --pull --target=dependency --build-arg="CACHEBUST=$(date +%s)" "$(dirname "$0")"

docker build --pull --tag="${DOCKERHUB_TAG}" "$(dirname "$0")"

# docker push "${DOCKERHUB_TAG}"
