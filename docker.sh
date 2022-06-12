#!/usr/bin/env bash

image='gparse-dev'

mydir="$(dirname "$0")/"
cd "$mydir"

docker build --tag="$image" . && \
docker run -it "$image" "$@"
