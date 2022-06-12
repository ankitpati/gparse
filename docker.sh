#!/usr/bin/env bash

image='gparse-dev'

mydir="$(dirname "$0")/"
cd "$mydir"

test "$#" -ne 0 && args=(-c "$*")

docker build --tag="$image" . && \
docker run -it "$image" "${args[@]}" # `docker run` if nothing above fails.
