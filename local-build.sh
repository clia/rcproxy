#!/bin/bash

IMAGE=ghcr.io/sterrenhemel/rcproxy
IMAGE_TAG=local

CURDIR=$(pwd)

# local build main
cargo build --all --release
# local build image
echo "build $IMAGE:$IMAGE_TAG"
docker buildx build --platform linux/amd64 -f Dockerfile -t $IMAGE:$IMAGE_TAG .
# push
docker login ghcr.io -u big-thousand -p $1
#docker push
docker push $IMAGE:$IMAGE_TAG