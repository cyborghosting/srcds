#!/bin/sh -eu

DOCKERHUB_TAG=cyborghosting/srcds


docker build --pull --tag="${DOCKERHUB_TAG}" "$(dirname "$0")" --progress=plain --build-arg=CACHEBUST=$(date '+%s.%N')

docker push "${DOCKERHUB_TAG}"
