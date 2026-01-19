#!/bin/sh -eu

DOCKERHUB_TAG=cyborghosting/srcds


docker build --pull --tag="${DOCKERHUB_TAG}" "$(dirname "$0")" --build-arg=CACHEBUST=$(date '+%s.%N') # --progress=plain

docker push "${DOCKERHUB_TAG}"
