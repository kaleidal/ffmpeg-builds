#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BINARY="${1:-}"
if [[ -z "${BINARY}" || ! -x "${BINARY}" ]]; then
  printf 'Usage: %s <ffmpeg-executable>\n' "$0" >&2
  exit 2
fi

DECODERS="$("${BINARY}" -hide_banner -decoders 2>&1)"
ENCODERS="$("${BINARY}" -hide_banner -encoders 2>&1)"
PROTOCOLS="$("${BINARY}" -hide_banner -protocols 2>&1)"
MUXERS="$("${BINARY}" -hide_banner -muxers 2>&1)"
DEMUXERS="$("${BINARY}" -hide_banner -demuxers 2>&1)"
FILTERS="$("${BINARY}" -hide_banner -filters 2>&1)"

grep -Eq '^[[:space:]]*A.*[[:space:]]truehd[[:space:]]' <<< "${DECODERS}"
grep -Eq '^[[:space:]]*A.*[[:space:]]mlp[[:space:]]' <<< "${DECODERS}"
! grep -Eq '^[[:space:]]*A.*[[:space:]]dca[[:space:]]' <<< "${DECODERS}"
! grep -Eq '^[[:space:]]*A.*[[:space:]]aac[[:space:]]' <<< "${DECODERS}"
grep -Eq '^[[:space:]]*A.*[[:space:]]libopus[[:space:]]' <<< "${ENCODERS}"
! grep -Eq '^[[:space:]]*V.*[[:space:]]' <<< "${ENCODERS}"
grep -Fxq '  https' <<< "${PROTOCOLS}"
grep -Eq '^[[:space:]]*E[[:space:]]+mp4[[:space:]]' <<< "${MUXERS}"
grep -Eq '^[[:space:]]*D[[:space:]]+matroska' <<< "${DEMUXERS}"
grep -Eq '^[[:space:]]*D[[:space:]]+mov' <<< "${DEMUXERS}"
grep -Eq '^[[:space:]]*D[[:space:]]+mpegts' <<< "${DEMUXERS}"
grep -Eq '^[[:space:]]*[.A-Z]+[[:space:]]+aformat[[:space:]]' <<< "${FILTERS}"
grep -Eq '^[[:space:]]*[.A-Z]+[[:space:]]+aresample[[:space:]]' <<< "${FILTERS}"

TLS_TEST_REVISION="${TLS_TEST_REVISION:-${GITHUB_SHA:-$(git -C "${SCRIPT_DIR}" rev-parse HEAD)}}"
"${BINARY}" \
  -hide_banner \
  -loglevel error \
  -f image2pipe \
  -vcodec pgm \
  -i "https://raw.githubusercontent.com/kaleidal/ffmpeg-builds/${TLS_TEST_REVISION}/testdata/tls.pgm" \
  -frames:v 1 \
  -c:v copy \
  -f null \
  -

"${BINARY}" -hide_banner -h decoder=truehd >/dev/null
"${BINARY}" -hide_banner -h encoder=libopus >/dev/null
