#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

TARGET=windows-x64
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

pushd "${OPUS_SOURCE_DIR}" >/dev/null
./configure \
  --prefix="${OPUS_PREFIX}" \
  --disable-doc \
  --disable-extra-programs \
  --disable-shared \
  --enable-static
make -j"$(nproc)"
make install
popd >/dev/null

export PKG_CONFIG_PATH="${OPUS_PREFIX}/lib/pkgconfig"

pushd "${FFMPEG_SOURCE_DIR}" >/dev/null
./configure \
  --arch=x86_64 \
  --target-os=mingw32 \
  --disable-autodetect \
  --disable-debug \
  --disable-doc \
  --disable-ffplay \
  --disable-ffprobe \
  --disable-gpl \
  --disable-nonfree \
  --enable-libopus \
  --enable-pic \
  --pkg-config-flags=--static \
  --enable-schannel \
  --enable-version3 \
  --extra-ldflags=-static
CONFIGURATION="$(sed -n 's/^FFMPEG_CONFIGURATION=//p' ffbuild/config.mak)"
make -j"$(nproc)" ffmpeg.exe
cp ffmpeg.exe "${OUTPUT_DIR}/ffmpeg.exe"
cp COPYING.LGPLv3 "${OUTPUT_DIR}/LICENSE.FFMPEG"
cp "${OPUS_SOURCE_DIR}/COPYING" "${OUTPUT_DIR}/LICENSE.OPUS"
popd >/dev/null

write_build_info "${OUTPUT_DIR}" "${TARGET}" "${CONFIGURATION}"
