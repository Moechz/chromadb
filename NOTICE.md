# Notices and attributions — ChromaDB for TerraMaster TOS

This repository contains **packaging only**. The ChromaDB application is
developed and distributed by its upstream authors; it is not modified here.

## Upstream application

| | |
|---|---|
| Project | ChromaDB ("Chroma") |
| Upstream repository | <https://github.com/chroma-core/chroma> |
| Upstream licence | **Apache License 2.0 (Apache-2.0)** — verified against the upstream `LICENSE` file, not copied from old metadata |
| Upstream copyright | Copyright Chroma Inc. and the Chroma contributors |
| Upstream release used | `1.5.9` (released 2026-05-05) |
| Full licence text | [`LICENSE-APACHE-2.0`](LICENSE-APACHE-2.0) |
| Changes made by this package | none to the application; packaging files only |

Earlier package metadata pointed `help` at a non-existent repository
(`Moechz/chroma`) and shipped no licence text. Both are corrected here.

## Container image

| | |
|---|---|
| Image | `chromadb/chroma:1.5.9` |
| Registry | Docker Hub |
| OCI image index | `sha256:1e0b73a187a28757c572acba508c46f48c9e8b0acaf5c20e6d95cdedce1acdf6` |
| Platforms | `linux/amd64` (x86_64) and `linux/arm64` (aarch64) — both manifests were pulled and verified while preparing this release |
| Digest pin | the tag above is immutable in practice for a released upstream version; the package records the index digest so a rebuilt release can be compared |

The image is used **unmodified**; the package only supplies a compose file and
the App Center metadata. The same multi-architecture image is used for both
architectures, so neither x86_64 nor aarch64 runs an emulated or
architecture-specific fork.

The image contains, among others:

- **ChromaDB 1.5.9** — Apache-2.0 (see above), including its Rust server binary
  and the self-hosted Swagger UI assets it serves at `/docs/`.
- **Debian GNU/Linux 13 (trixie)** userland — the licences of the shipped
  packages (glibc, OpenSSL, zlib, ca-certificates, …).
- **dumb-init** — MIT, used as PID 1 to reap child processes.

The authoritative licence files for these components are shipped inside the
upstream image and in the upstream source repository.

## This packaging

| | |
|---|---|
| Packaging files (`src/`, `scripts/`, `tools/`, `test/`, README, CHANGELOG, PRIVACY, this notice) | **MIT** — see [`LICENSE`](LICENSE) |
| Copyright | Copyright (c) 2026 Moechz |
| Privacy policy | [`PRIVACY.md`](PRIVACY.md) — also the target of the package `help` link |

The packaging files are original work. They contain no copy of the upstream
application source code, so the Apache-2.0 obligations for the application are
fulfilled by the upstream project and its published image; this repository does
not redistribute a modified ChromaDB binary.

## Trademarks and affiliation

- **Chroma**, **ChromaDB** and **Chroma Cloud** are the names/marks of Chroma
  Inc. and its project. They are used here only to identify the application
  that this package installs.
- **TerraMaster** and **TOS** are trademarks of TerraMaster.
- This is an independent community package by **Moechz**. It is not affiliated
  with, endorsed by, or sponsored by Chroma Inc. or TerraMaster.
- The application icon in `src/chromadbdocker.svg` is a simplified monochrome
  ring glyph produced for this package; it is not a copy of the upstream logo
  files.

## Security note (CVE remediation)

The previous package shipped `chromadb/chroma:0.6.3` (March 2025). The App
Center review flagged high/critical CVEs in that image (code **T1**). The 0.6.x
series is no longer maintained upstream, and the review scan is against the
image, so the only real fix is to move to a maintained upstream release:

- this package now ships **1.5.9** (latest upstream release, May 2026), which
  carries a current Debian base and a current Rust server instead of the frozen
  Python 3.11 / `uvicorn` / `onnxruntime` stack that produced the findings;
- no CVE is fixed by patching inside this repository — the package never
  contains application code.

The upgrade is a **major version change** (0.6.x → 1.x storage layout). The old
data directory is preserved, not deleted; README.md documents the export and
rollback procedure.
