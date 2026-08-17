#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"
source "${SCRIPT_DIR}/ffmpeg-flags.sh"

TARGET="${1:-}"
case "${TARGET}" in
  linux-x64|macos-x64|macos-arm64) ;;
  *)
    printf 'Usage: %s <linux-x64|macos-x64|macos-arm64>\n' "$0" >&2
    exit 2
    ;;
esac

BUILD_DIR="${REPO_DIR}/build/${TARGET}"
OUTPUT_DIR="${REPO_DIR}/dist/${TARGET}"
FFMPEG_ARCHIVE="${BUILD_DIR}/ffmpeg-${FFMPEG_VERSION}.tar.xz"
FFMPEG_SOURCE_DIR="${BUILD_DIR}/ffmpeg-${FFMPEG_VERSION}"
OPUS_ARCHIVE="${BUILD_DIR}/opus-${OPUS_VERSION}.tar.gz"
OPUS_SOURCE_DIR="${BUILD_DIR}/opus-${OPUS_VERSION}"
OPUS_PREFIX="${BUILD_DIR}/opus-install"

rm -rf "${BUILD_DIR}" "${OUTPUT_DIR}"
mkdir -p "${BUILD_DIR}" "${OUTPUT_DIR}"

download_verified \
  "https://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.xz" \
  "${FFMPEG_ARCHIVE}" \
  "${FFMPEG_SOURCE_SHA256}"
tar -xf "${FFMPEG_ARCHIVE}" -C "${BUILD_DIR}"

download_verified \
  "https://ftp.osuosl.org/pub/xiph/releases/opus/opus-${OPUS_VERSION}.tar.gz" \
  "${OPUS_ARCHIVE}" \
  "${OPUS_SOURCE_SHA256}"
tar -xf "${OPUS_ARCHIVE}" -C "${BUILD_DIR}"

COMMON_FLAGS=(
  --disable-autodetect
  --disable-debug
  --disable-doc
  --disable-ffplay
  --disable-ffprobe
  --disable-gpl
  --disable-nonfree
  --enable-libopus
  --enable-pic
  --pkg-config-flags=--static
  --enable-version3
  "${RAFFI_FFMPEG_FLAGS[@]}"
)

if [[ "${TARGET}" == "linux-x64" ]]; then
  OPENSSL_ARCHIVE="${BUILD_DIR}/openssl-${OPENSSL_VERSION}.tar.gz"
  OPENSSL_SOURCE_DIR="${BUILD_DIR}/openssl-${OPENSSL_VERSION}"
  OPENSSL_PREFIX="${BUILD_DIR}/openssl-install"

  download_verified \
    "https://github.com/openssl/openssl/releases/download/openssl-${OPENSSL_VERSION}/openssl-${OPENSSL_VERSION}.tar.gz" \
    "${OPENSSL_ARCHIVE}" \
    "${OPENSSL_SOURCE_SHA256}"
  tar -xf "${OPENSSL_ARCHIVE}" -C "${BUILD_DIR}"

  pushd "${OPENSSL_SOURCE_DIR}" >/dev/null
  ./Configure linux-x86_64 no-apps no-docs no-shared no-tests \
    --prefix="${OPENSSL_PREFIX}" \
    --openssldir=/etc/ssl \
    --libdir=lib
  make -j"$(nproc)"
  make install_sw
  popd >/dev/null

  export PKG_CONFIG_PATH="${OPENSSL_PREFIX}/lib/pkgconfig:${OPUS_PREFIX}/lib/pkgconfig"
  PLATFORM_FLAGS=(
    --arch=x86_64
    --enable-openssl
    --pkg-config-flags=--static
    --extra-ldflags=-static-libgcc
  )
else
  if [[ "${TARGET}" == "macos-x64" ]]; then
    ARCH=x86_64
  else
    ARCH=arm64
  fi
  MINIMUM_MACOS_VERSION=11.0
  export MACOSX_DEPLOYMENT_TARGET="${MINIMUM_MACOS_VERSION}"
  PLATFORM_FLAGS=(
    --arch="${ARCH}"
    --cc="clang -arch ${ARCH}"
    --enable-securetransport
    --extra-cflags="-arch ${ARCH} -mmacosx-version-min=${MINIMUM_MACOS_VERSION}"
    --extra-ldflags="-arch ${ARCH} -mmacosx-version-min=${MINIMUM_MACOS_VERSION}"
  )
  export CFLAGS="-arch ${ARCH} -mmacosx-version-min=${MINIMUM_MACOS_VERSION}"
  export LDFLAGS="-arch ${ARCH} -mmacosx-version-min=${MINIMUM_MACOS_VERSION}"
  export PKG_CONFIG_PATH="${OPUS_PREFIX}/lib/pkgconfig"
fi

pushd "${OPUS_SOURCE_DIR}" >/dev/null
./configure \
  --prefix="${OPUS_PREFIX}" \
  --disable-doc \
  --disable-extra-programs \
  --disable-shared \
  --enable-static
make -j"$(getconf _NPROCESSORS_ONLN 2>/dev/null || sysctl -n hw.logicalcpu)"
make install
popd >/dev/null

pushd "${FFMPEG_SOURCE_DIR}" >/dev/null
./configure "${COMMON_FLAGS[@]}" "${PLATFORM_FLAGS[@]}"
CONFIGURATION="$(sed -n 's/^FFMPEG_CONFIGURATION=//p' ffbuild/config.mak)"
make -j"$(getconf _NPROCESSORS_ONLN 2>/dev/null || sysctl -n hw.logicalcpu)" ffmpeg
cp ffmpeg "${OUTPUT_DIR}/ffmpeg"
cp COPYING.LGPLv3 "${OUTPUT_DIR}/LICENSE.FFMPEG"
cp "${OPUS_SOURCE_DIR}/COPYING" "${OUTPUT_DIR}/LICENSE.OPUS"
popd >/dev/null

if [[ "${TARGET}" == "linux-x64" ]]; then
  cp "${OPENSSL_SOURCE_DIR}/LICENSE.txt" "${OUTPUT_DIR}/LICENSE.OPENSSL"
fi

chmod 0755 "${OUTPUT_DIR}/ffmpeg"
write_build_info "${OUTPUT_DIR}" "${TARGET}" "${CONFIGURATION}"
