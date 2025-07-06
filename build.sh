#!/bin/sh -eu

DOCKERHUB_TAG=cyborghosting/srcds


docker build --pull --tag="${DOCKERHUB_TAG}" "$(dirname "$0")"

docker push "${DOCKERHUB_TAG}"
