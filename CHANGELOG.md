# Changelog

All notable user-visible changes to the ChromaDB TOS application package.
The version scheme is `<upstream version>-<packaging iteration>`.

## 1.5.9-1 — 2026-11-22

Remediation of the App Center review for `0.6.3-3` (x86_64 and aarch64).
Review codes addressed: **C3, C4, C5, C6, C7, C8, C10, T1, F7, S11**.

### Security / upstream (T1)
- **Upgraded the application from `chromadb/chroma:0.6.3` to
  `chromadb/chroma:1.5.9`** (latest upstream release, 2026-05-05). The 0.6.x
  series is unmaintained and its frozen Python 3.11 / `uvicorn` / ONNX stack is
  what the review's high/critical CVE scan flagged. The 1.x image ships a
  current Debian 13 base and the current Rust server, so the affected
  components are replaced rather than patched. `NOTICE.md` records the image
  index digest and the platforms.
- The same multi-arch tag is used for x86_64 and aarch64 (both manifests pulled
  and verified); no architecture-specific fork.
- Major-version storage change: 1.x uses a new layout. Data written by 0.6.x in
  `data/chroma/` is preserved untouched, and README.md documents the export /
  re-import procedure and the rollback path.

### Telemetry and data collection (C6)
- Upstream 0.6.x sent anonymized product telemetry to PostHog **by default**.
  This package now pins `ANONYMIZED_TELEMETRY=False` in the compose file, and
  1.5.9 contains no telemetry provider at all (the server prints
  `No telemetry is configured.`). The event list, the data actually sent when
  it is enabled, and how to switch it are now declared in `PRIVACY.md` §4 — the
  previous package declared "no telemetry" while the image sent some, which is
  exactly the C6 finding.

### Privacy policy (C3, C4, C5, C7)
- Added **`PRIVACY.md`**: what is stored (collections, records, embeddings,
  index segments, logs), where it is stored, the complete third-party endpoint
  table, retention period, user rights (access / rectification / erasure /
  restriction / complaint), the deletion channel (API, file system, uninstall),
  the security measures, children, and the change procedure.
- `help` in `config.ini` now points at
  <https://github.com/Moechz/chromadb/blob/main/PRIVACY.md> (it previously
  pointed at the non-existent repository `Moechz/chroma`), so the policy opens
  from App Center.

### Third-party APIs (C8)
- Disclosed every endpoint the app can touch, with purpose, data and
  destination: Docker Hub (image pull), PostHog (only if telemetry is switched
  on), and the client-side embedding-model download
  (`chroma-onnx-models.s3.amazonaws.com`) / hosted embedding providers that the
  *client*, not this container, may call. Verified that the server rejects
  `add` requests without embeddings, i.e. it never embeds or downloads a model
  itself.

### Web interface (F7)
- The App Center entry point now opens the server's own interactive API console
  at `http://<NAS-IP>:8141/docs/` instead of the API root, which answered
  `404 {"detail":"Not Found"}`. The Swagger UI is served by the container (no
  CDN, no external font), measured at ~2 ms first byte in staging, and the
  OpenAPI document plus `/api/v2/*` keep working on the same port 8141.
- Verified `/api/v2/heartbeat`, `/api/v2/version`, `/openapi.json`, `/docs/`
  and a real `create collection → add vectors → query` round trip against the
  staged container.

### Permissions and runtime (S11)
- File permissions minimised: the container root filesystem is now
  **read-only**, `/tmp` is an in-memory tmpfs, all Linux capabilities are
  dropped (`cap_drop: [ALL]`) and `no-new-privileges` is set. The service still
  runs as `1000:1000`; the only writable path is the mounted data directory.
- The 0.6.x entrypoint wrapper is gone: 1.x logs to stdout and needs no
  writable working directory, so the upstream image runs unmodified (fewer
  moving parts, no shell in the start path).
- Health check rewritten for the 1.x image (no `curl`/`wget` inside): it reads
  `GET /api/v2/heartbeat` over `/dev/tcp` with the bundled `bash`.

### Repository and documentation (C10)
- Complete `README.md`: repository layout, how it works, privacy summary,
  notices, build and verification, data/uninstall, 0.6.x migration, security
  notes and the submission checklist.
- Added `NOTICE.md` (upstream licence verified as Apache-2.0, image digest,
  platforms, trademarks, packaging licence) and `LICENSE-APACHE-2.0` (the
  upstream licence text). The repository is public.
- Removed the stale `probe` block (with the old failed trial run) and the
  `entrypoint_file` residue from `tosapp.json`.

## 0.6.3-2 — 2026-11-15

### Added
- First release. ChromaDB (`chromadb/chroma:0.6.3`, Docker Hub official image, unmodified)
  packaged as a TOS 7 Docker application, published on port 8141 and running
  as a non-root user (1000:1000).
- Persistent data is kept under `/Volume1/DockerAppData/chromadbdocker/`.
