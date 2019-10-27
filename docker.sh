#!/usr/bin/env bash

image='gparsedev'

mydir="$(dirname "$0")/"
cd "$mydir"

docker image inspect "$image" &>/dev/null || \
docker build --tag="$image" . && \
docker run -it "$image" "$@"
