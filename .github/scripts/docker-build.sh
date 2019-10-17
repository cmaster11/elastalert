#!/usr/bin/env bash
set -Eeuxmo pipefail
DIR="$(dirname "$(command -v greadlink >/dev/null 2>&1 && greadlink -f "$0" || readlink -f "$0")")"

# --- Config
IMAGE_NAME=$(cat "$DIR/../../DOCKER_IMAGE_NAME")
DOCKERFILE="$DIR/../../Dockerfile"

# ---
DEFAULT_VERSION=$(git describe --tags 2>/dev/null || echo 'master')
FILE_VERSION=$(cat "$DIR/../../DOCKER_BUILD_VERSION" || echo "$DEFAULT_VERSION")
VERSION="${DOCKER_BUILD_VERSION:-$FILE_VERSION}"

docker build -t "$IMAGE_NAME:$VERSION" -f "$DOCKERFILE" "$DIR/../.."
docker tag "$IMAGE_NAME:$VERSION" "$DOCKER_REPO/$IMAGE_NAME:$VERSION"
docker push "$DOCKER_REPO/$IMAGE_NAME:$VERSION"