#!/bin/bash

REPOSITORY=${REPOSITORY:-"docker.io/zouguangxian/solana"}
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

printf "target/\n.dockerignore" > ${DIR}/../.dockerignore \
&& docker buildx build \
    --progress=plain \
    --platform=linux/amd64,linux/arm64 \
    --build-arg BUILT_VIA_BUILDKIT="true" \
    --build-arg GIT_SHA=$(git rev-parse HEAD) \
    --build-arg GIT_BRANCH=$(git symbolic-ref --short HEAD) \
    --build-arg GIT_TAG=$( git describe --tags) \
    --build-arg GIT_CREDENTIALS="${GIT_CREDENTIALS:-}" \
    --build-arg BUILD_DATE="$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
    --build-arg CI_COMMIT=$(git rev-parse --short=8 HEAD) \
    --target tools \
    --tag ${REPOSITORY}:$(git describe --abbrev=0 --tags) \
    -f ${DIR}/Dockerfile ${DIR}/.. --push

