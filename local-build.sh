#!/bin/bash

IMAGE=glenaaa/rcproxy
IMAGE_TAG=local

CURDIR=$(pwd)

rustup target add x86_64-unknown-linux-musl
# local build main
cargo build --target x86_64-unknown-linux-musl --release
# local build image
echo "build $IMAGE:$IMAGE_TAG"
docker buildx build --platform linux/amd64 -f local.Dockerfile -t $IMAGE:$IMAGE_TAG .
# push
# docker login ghcr.io -u big-thousand -p $1
docker login -u glenaaa -p $1
#docker push
docker push $IMAGE:$IMAGE_TAG