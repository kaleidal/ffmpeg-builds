#!/usr/bin/env bash
set -euo pipefail

BINARY="${1:-}"
if [[ -z "${BINARY}" || ! -x "${BINARY}" ]]; then
  printf 'Usage: %s <ffmpeg-executable>\n' "$0" >&2
  exit 2
fi

TEST_DIR="$(mktemp -d)"
trap 'rm -rf "${TEST_DIR}"' EXIT

DECODERS="$("${BINARY}" -hide_banner -decoders 2>&1)"
ENCODERS="$("${BINARY}" -hide_banner -encoders 2>&1)"
PROTOCOLS="$("${BINARY}" -hide_banner -protocols 2>&1)"
MUXERS="$("${BINARY}" -hide_banner -muxers 2>&1)"

grep -Eq '^[[:space:]]*A.*[[:space:]]dca[[:space:]]' <<< "${DECODERS}"
grep -Eq '^[[:space:]]*A.*[[:space:]]aac[[:space:]]' <<< "${ENCODERS}"
grep -Fxq '  https' <<< "${PROTOCOLS}"
grep -Eq '^[[:space:]]*E[[:space:]]+mp4[[:space:]]' <<< "${MUXERS}"

"${BINARY}" \
  -hide_banner \
  -loglevel error \
  -i 'https://samples.ffmpeg.org/A-codecs/truespeech/tada.wav' \
  -f null \
  -

"${BINARY}" \
  -hide_banner \
  -loglevel error \
  -f lavfi \
  -i 'sine=frequency=997:sample_rate=48000:duration=1' \
  -strict experimental \
  -c:a dca \
  -y "${TEST_DIR}/source.dts"

"${BINARY}" \
  -hide_banner \
  -loglevel error \
  -i "${TEST_DIR}/source.dts" \
  -c:a aac \
  -b:a 192k \
  -movflags frag_keyframe+empty_moov+default_base_moof \
  -f mp4 \
  -y "${TEST_DIR}/output.mp4"

DECODE_OUTPUT="$("${BINARY}" -hide_banner -i "${TEST_DIR}/output.mp4" -f null - 2>&1)"
grep -Eq 'Audio: aac' <<< "${DECODE_OUTPUT}"
