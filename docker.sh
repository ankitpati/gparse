#!/usr/bin/env bash

image='gparsedev'

mydir="$(dirname "$0")/"
cd "$mydir"

test "$#" -ne 0 && args=(-lc "$*")

docker build --tag="$image" . && \
docker run -it "$image" "${args[@]}" # `docker run` if nothing above fails.
