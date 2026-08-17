#!/usr/bin/env bash

RAFFI_FFMPEG_FLAGS=(
  --disable-everything
  --enable-bsf=aac_adtstoasc,extract_extradata
  --enable-decoder=alac,ape,atrac1,atrac3,atrac3al,atrac3plus,atrac3plusal,atrac9,cook,mlp,pgm,ralf,real_144,real_288,sipr,tak,truehd,tta,wavpack,wmav1,wmav2,wmapro,wmavoice
  --enable-demuxer=image2pipe,matroska,mov,mpegts
  --enable-encoder=libopus
  --enable-filter=aformat,aresample
  --enable-muxer=mp4,null
  --enable-parser=aac,av1,h264,hevc,mpegaudio,opus,vp9
  --enable-protocol=crypto,data,file,http,httpproxy,https,pipe,tcp,tls
)
