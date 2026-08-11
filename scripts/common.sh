#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

set -a
source "${REPO_DIR}/versions.env"
set +a

sha256_file() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}

download_verified() {
  local url="$1"
  local output="$2"
  local expected_sha256="$3"
  local actual_sha256

  curl --fail --location --retry 4 --retry-all-errors --output "${output}" "${url}"
  actual_sha256="$(sha256_file "${output}")"
  if [[ "${actual_sha256}" != "${expected_sha256}" ]]; then
    printf 'Checksum mismatch for %s\nexpected: %s\nactual:   %s\n' \
      "${output}" "${expected_sha256}" "${actual_sha256}" >&2
    exit 1
  fi
}

write_build_info() {
  local output_dir="$1"
  local target="$2"
  local configuration="$3"

  {
    printf 'target=%s\n' "${target}"
    printf 'ffmpeg_version=%s\n' "${FFMPEG_VERSION}"
    printf 'ffmpeg_source_sha256=%s\n' "${FFMPEG_SOURCE_SHA256}"
    printf 'openssl_version=%s\n' "${OPENSSL_VERSION}"
    printf 'openssl_source_sha256=%s\n' "${OPENSSL_SOURCE_SHA256}"
    printf 'build_revision=%s\n' "${BUILD_REVISION}"
    printf 'configure=%s\n' "${configuration}"
  } > "${output_dir}/BUILD-INFO.txt"
}
