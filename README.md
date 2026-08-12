# Kaleidal FFmpeg builds

Pinned-source, cross-platform FFmpeg executables for Kaleidal desktop applications. The builds are designed for remuxing browser-compatible video while transcoding unsupported audio such as DTS to browser-safe multichannel Opus.

The current release targets:

- Linux x64
- Windows x64
- macOS universal, containing x64 and arm64 slices

## Release contents

Every archive contains the FFmpeg executable, its exact build configuration, FFmpeg and dependency licenses, and source provenance. Releases also include SHA-256 checksums and GitHub build-provenance attestations.

The build deliberately excludes GPL and nonfree options. FFmpeg is configured as LGPLv3, using its native DTS decoder and pinned libopus encoder. Linux HTTPS support is statically linked against the pinned OpenSSL LTS release; Windows and macOS use their platform TLS implementations.

## Building locally

Linux and macOS builds use:

```sh
./scripts/build-unix.sh linux-x64
./scripts/build-unix.sh macos-arm64
./scripts/build-unix.sh macos-x64
```

Windows builds run from an MSYS2 MinGW x64 shell:

```sh
./scripts/build-windows.sh
```

Build output is written to `dist/<target>`. The scripts download only sources pinned in `versions.env` and reject mismatched checksums.

## Automatic FFmpeg updates

GitHub Actions checks FFmpeg's official stable release directory every day at 05:17 UTC. The same check can be started from the Actions page with the **Run workflow** button.

When a newer stable version is available, the updater:

1. Records the version and verified source checksum in `versions.env`.
2. Resets `BUILD_REVISION` to `1`.
3. Commits the pin to `main`.
4. Creates and pushes an immutable `v<version>-raffi.1` tag.
5. Explicitly starts the release workflow at that tag and verifies the run was created.
6. Builds and tests Linux, Windows, macOS x64, and macOS arm64.
7. Packages the universal macOS binary and publishes the release only after every build and codec test passes.

The release contains checksummed source archives, platform binaries, licenses, build metadata, and GitHub build-provenance attestations. Development snapshots are not selected by the updater.

## Updating consumers

Applications intentionally do not download an unreviewed release just because it is new. After a release succeeds, update the release tag and platform archive checksums in the application's FFmpeg manifest. Raffi stores these pins in `apps/desktop/ffmpeg.json`; its `prepare:ffmpeg` command downloads and verifies the selected artifact, and desktop packaging runs that command automatically.

## Publishing build changes

When build flags or a pinned dependency change without a new FFmpeg release, update their values and checksums in `versions.env`, increment `BUILD_REVISION`, and run at least one local build. Commit and push the change before creating the matching tag:

```sh
source versions.env
tag="v${FFMPEG_VERSION}-raffi.${BUILD_REVISION}"
git tag -a "${tag}" -m "FFmpeg ${FFMPEG_VERSION} for Raffi build ${BUILD_REVISION}"
git push origin main "${tag}"
```

Pushing the tag starts the release workflow. It validates the tag against `versions.env`, and all platform builds and codec tests must pass before the GitHub release is created. Release tags are immutable.

## License

The build scripts are MIT licensed. FFmpeg, OpenSSL, and libopus retain their own licenses, which are included with every relevant artifact. Consumers must comply with those licenses and make the corresponding source available.
