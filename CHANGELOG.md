# Changelog

All notable user-visible changes to the ChromaDB TOS application package.

## 0.6.3-1 — 2026-11-15

### Added
- First release. ChromaDB (`chromadb/chroma:0.6.3`, Docker Hub official image, unmodified)
  packaged as a TOS 7 Docker application, published on port 8128 and running
  as a non-root user (1000:1000).
- Persistent data is kept under `/Volume1/DockerAppData/chromadbdocker/`.
