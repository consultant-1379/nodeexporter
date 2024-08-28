#!/bin/bash

IMAGE=$1
shift
VOLUME=$1
shift

echo "$@"

docker run --rm --user $(id -u):$(id -g) \
 --volume ${VOLUME}:/rpm \
 ${IMAGE} \
 bash "$@"
