#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/common.sh"

releases=$(curl --fail --location --retry 3 --retry-all-errors --silent --show-error https://ffmpeg.org/releases/)
latest=$(
  printf '%s' "${releases}" |
    sed -nE 's/.*href="ffmpeg-([0-9]+\.[0-9]+(\.[0-9]+)?)\.tar\.xz".*/\1/p' |
    sort -V |
    tail -n 1
)
if [[ -z "${latest}" ]]; then
  echo "Could not determine the latest stable FFmpeg release" >&2
  exit 1
fi

archive=$(mktemp)
trap 'rm -f "${archive}"' EXIT
curl --fail --location --retry 3 --retry-all-errors --output "${archive}" \
  "https://ffmpeg.org/releases/ffmpeg-${latest}.tar.xz"
sha=$(sha256_file "${archive}")

printf 'FFMPEG_VERSION=%s\nFFMPEG_SOURCE_SHA256=%s\n' "${latest}" "${sha}"
