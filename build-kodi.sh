#!/bin/bash

docker build -t kodi-builder .

docker run \
  --rm \
  -v $PWD/:/artifacts \
  kodi-builder \
  cp /kodi-built.tgz /artifacts/
