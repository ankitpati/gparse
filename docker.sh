#!/usr/bin/env bash

image='gparsedev'

mydir="$(dirname "$0")/"
cd "$mydir"

test "$#" -ne 0 && args=(-lc "$*")

{
    docker image inspect "$image" &>/dev/null && \
    file_epoch="$(stat -c'%Y' 'Dockerfile')" && \
    image_ts="$(docker image inspect "$image" | jq -r '.[].Created')" && \
    image_epoch="$(date -d"$image_ts" +'%s')" && \
    test "$file_epoch" -lt "$image_epoch"
    # `docker build` only if `Dockerfile` is newer than tagged image.
} || \
docker build --tag="$image" . && \
docker run -it "$image" "${args[@]}" # `docker run` if nothing above fails.
