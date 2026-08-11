# Kaleidal FFmpeg builds

Pinned-source, cross-platform FFmpeg executables for Kaleidal desktop applications. The builds are designed for remuxing browser-compatible video while transcoding unsupported audio such as DTS to AAC.

The current release targets:

- Linux x64
- Windows x64
- macOS universal, containing x64 and arm64 slices

## Release contents

Every archive contains the FFmpeg executable, its exact build configuration, FFmpeg and dependency licenses, and source provenance. Releases also include SHA-256 checksums and GitHub build-provenance attestations.

The build deliberately excludes GPL and nonfree options. FFmpeg is configured as LGPLv3, using its native DTS decoder and AAC encoder. Linux HTTPS support is statically linked against the pinned OpenSSL LTS release; Windows and macOS use their platform TLS implementations.

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

## Publishing

The release workflow validates that its Git tag matches the version and revision in `versions.env`:

```sh
git tag v9.0-raffi.1
git push origin v9.0-raffi.1
```

All platform builds and codec tests must pass before the GitHub release is created.

The update workflow checks FFmpeg's stable source archive daily. When a newer version appears, it commits the new version and checksum, creates build revision 1, and explicitly starts the release workflow at that immutable tag.

## Updating FFmpeg

Update the versions and source checksums in `versions.env`, run at least one local build, then increment `BUILD_REVISION` only when the build configuration changes without changing the FFmpeg version. Release tags are immutable.

Use stable FFmpeg release tags for Raffi. Development snapshots can be tested on branches but should not replace a pinned application dependency.

## License

The build scripts are MIT licensed. FFmpeg and OpenSSL retain their own licenses, which are included with every artifact. Consumers must comply with those licenses and make the corresponding source available.
