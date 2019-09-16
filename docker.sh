#!/usr/bin/env bash

mydir="$(dirname "$0")/"
cd "$mydir"

docker build --tag='gparsedev' . && \
docker run --mount type=bind,src="$(pwd)",dst='/opt/gparse' \
    --publish 3000:3000 \
    --publish 8080:8080 \
    -it gparsedev "$@"
