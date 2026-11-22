# chromadb-for-tos

> TerraMaster TOS 7 App Center — **Docker application** package for
> [ChromaDB](https://github.com/chroma-core/chroma) 1.5.9.

## What this is

A four-file TOS Docker application archive (`chromadbdocker.tar.gz`) that
installs ChromaDB on TOS 7 through the App Center:

- `config.ini` — TOS application metadata (`application_type: docker`, id `chromadbdocker`)
- `chromadbdocker.lang` — 23-language store text (TOS requires 14)
- `chromadbdocker.svg` — application icon
- `docker-compose.yml` — one service, image `chromadb/chroma:1.5.9`

## How it works

| | |
|---|---|
| Container image | `chromadb/chroma:1.5.9` (Docker Hub, used unmodified, multi-arch amd64 + arm64) |
| Open | `http://<NAS-IP>:8141/docs/` — interactive API console (container port 8000) |
| API | `http://<NAS-IP>:8141/api/v2/...`, health `GET /api/v2/heartbeat`, spec `/openapi.json` |
| Runs as | non-root `user: "1000:1000"`, read-only root filesystem, `cap_drop: [ALL]`, `no-new-privileges` |
| Persistent data | `/Volume1/DockerAppData/chromadbdocker/data` → `/data` |
| Logs | `docker logs chromadbdocker` (stdout/stderr; no log file on the volume) |
| Health check | HTTP `GET /api/v2/heartbeat` from inside the container |

ChromaDB is **API-first**: it has no management web UI. The page the App
Center opens (`/docs/`) is the Swagger UI that the server itself hosts — you
can browse every endpoint, try requests against your own collections, and read
the JSON schema. All of its assets are served by the container, so the page
works on a NAS without internet access and paints in milliseconds.

## Repository layout

```
.
├── src/                       # files that go into the package
│   ├── config.ini             # TOS metadata (id, name, port, help link, version/platform placeholders)
│   ├── chromadbdocker.lang    # 23-language store text (generated from tosapp.json translations)
│   ├── chromadbdocker.svg     # application icon (512×512 viewBox, store limits respected)
│   └── docker-compose.yml     # the single service: image, port 8141:8000, volume, healthcheck
├── scripts/
│   ├── build.sh               # stage + substitute + verify + pack one architecture
│   └── build-dual.sh          # build x86_64 + aarch64 and run the official check on both
├── tools/
│   └── verify.py              # packaging self-check (layout, metadata, compose rules, version, icon)
├── test/
│   └── install-and-verify.sh  # on-device end-to-end check (needs root on the NAS)
├── tosapp.json                # the packaging spec the scripts read (image, ports, env, translations)
├── PRIVACY.md                 # privacy policy (also the target of the App Center "Help" link)
├── NOTICE.md                  # upstream licence, image digest, trademarks, packaging licence
├── LICENSE                    # MIT — the packaging itself
├── LICENSE-APACHE-2.0         # upstream ChromaDB licence, shipped for attribution
├── CHANGELOG.md               # one entry per released package version
└── README.md                  # this file
```

## Privacy

This application runs entirely on your NAS. **No documents, metadata,
embeddings, queries or collection names ever leave the NAS.**

- Upstream ChromaDB 0.6.x reported **anonymized** usage telemetry to PostHog by
  default. This package (1.5.9) contains no telemetry provider at all — the
  server prints `No telemetry is configured.` — and it additionally pins
  `ANONYMIZED_TELEMETRY=False` so the choice is explicit and reviewable.
- The container makes no outbound request on start-up: no licence check, no
  update ping, no crash reporting.
- Embeddings are computed by **your client** (for example the Python SDK), not
  by this container. If your client uses a hosted embedding provider, your text
  goes from your machine to that provider under their policy; the server here
  only ever receives the resulting vectors.
- The only third-party endpoints involved are documented with purpose, data and
  destination in [`PRIVACY.md`](PRIVACY.md) §3.

Read the full policy — storage locations, retention, user rights, security
measures, deletion channel — in [`PRIVACY.md`](PRIVACY.md). It is also reachable
from App Center via the package `help` link:
<https://github.com/Moechz/chromadb/blob/main/PRIVACY.md>

## Notices

The package runs the upstream image `chromadb/chroma:1.5.9` unmodified.
ChromaDB is distributed under the **Apache License 2.0**; the full text is in
[`LICENSE-APACHE-2.0`](LICENSE-APACHE-2.0). The image also contains a Debian 13
userland and `dumb-init` (MIT). The packaging files in this repository are
**MIT** ([`LICENSE`](LICENSE)).

Attribution, image digest, platforms and the trademark statement are in
[`NOTICE.md`](NOTICE.md).

## Build

```bash
scripts/build-dual.sh              # both architectures + official check
scripts/build.sh 1.5.9-1           # one architecture (x86_64 by default)
scripts/build.sh 1.5.9-1 aarch64   # one architecture explicitly
```

`build.sh` stages the four files, substitutes the version/platform
placeholders, validates the JSON/INI/YAML, removes CRLF/BOM/AppleDouble, runs
`tools/verify.py` (archive layout, JSON validity, required fields, 14+
languages, version consistency, Docker-Hub-only images, fixed tag,
reserved/recommended host ports, non-root user, per-service
healthcheck/TZ/restart, data path below the application data root, never the
`/Volume*` wildcard, comment-free sequence blocks, `x-app-meta` position, no
literal secrets, icon size/element limits), then packs a deterministic
`tar.gz` (uid/gid 0, zeroed mtimes) with a `.sha256` next to it.

`build-dual.sh` keeps `out/chromadbdocker_x86_64.tar.gz`,
`out/chromadbdocker_aarch64.tar.gz` and their `.sha256` files, and runs the
official `TOSAppSelfTestingTool -c` against both.

## Local verification

```bash
./TOSAppSelfTestingTool -c out/chromadbdocker_x86_64.tar.gz   # official spec check
./TOSAppSelfTestingTool -c out/chromadbdocker_aarch64.tar.gz
python3 ../stage.py . --timeout 300                            # isolated run: non-root + HTTP
bash test/install-and-verify.sh out/chromadbdocker_x86_64.tar.gz   # on-device E2E (root)
```

`stage.py` (in the packaging workspace) unpacks the archive, rewrites the
compose file to a spare loopback port and a throw-away data directory, starts
it, asserts *running + healthy + HTTP answer + `user=1000:1000`*, then removes
everything. It never touches the installed instance or its data.

## Data, uninstall and upgrade

- **Data directory:** `/Volume1/DockerAppData/chromadbdocker/data/`
  - `chroma.sqlite3` — collections, records (ids, documents, metadata, vectors)
  - `<uuid>/` — HNSW index segments (`header.bin`, `data_level0.bin`, …)
- **Backup:** stop the container (or use a snapshot) and copy the whole data
  directory. That is a complete, consistent backup of the database.
- **Uninstall:** in App Center, uninstall ChromaDB. Docker packages have no
  uninstall hook, so the data directory is **left in place**; choose the
  "delete application data" option, or delete
  `/Volume1/DockerAppData/chromadbdocker/` yourself, to remove it. Deleting the
  data directory deletes every collection permanently.
- **Update / rollback:** the image tag is fixed per package version, so an
  update replaces the container, never the data. To roll back, reinstall the
  previous package version (if still offered) — the data directory is not
  touched by installing or uninstalling.

### Upgrading from 0.6.x (this release is a major version change)

0.6.x stored its database in `data/chroma/` (its own `chroma.sqlite3` plus
index folders). ChromaDB 1.x uses a new storage layout rooted at `data/`.
This package therefore:

- **keeps** `data/chroma/` exactly as it is (nothing is deleted or rewritten);
- starts a **fresh** 1.x store at `data/chroma.sqlite3`.

Old collections are **not** visible in 1.x until you export and re-insert them.
To migrate:

```bash
# 1. Stop the app (App Center → ChromaDB → Stop).
# 2. Keep a copy of the old store before anything else.
sudo cp -a /Volume1/DockerAppData/chromadbdocker/data/chroma \
           /Volume1/DockerAppData/chromadbdocker/data/chroma-0.6.3-backup
```

```python
# 3. On a machine that can read that folder (pip install "chromadb==0.6.3"), copy
#    the collections into the running 1.x instance.
import chromadb

old = chromadb.PersistentClient(path="/path/to/chroma-0.6.3-backup")
new = chromadb.HttpClient(host="<NAS-IP>", port=8141)

for meta in old.list_collections():
    src = old.get_collection(meta.name)
    data = src.get(include=["embeddings", "documents", "metadatas"])
    dst = new.get_or_create_collection(meta.name)
    dst.add(ids=data["ids"], embeddings=data["embeddings"],
            documents=data["documents"], metadatas=data["metadatas"])
    print(meta.name, len(data["ids"]), "records copied")
```

If you would rather keep the old database as-is, stay on the 0.6.x package —
but note that 0.6.x is no longer maintained upstream and is exactly what the
review's CVE finding (T1) was about.

## Security notes

- The container is non-root, has a read-only root filesystem, drops all Linux
  capabilities, sets `no-new-privileges`, uses no `privileged` mode, no host
  networking and no Docker socket. `/tmp` is a tmpfs.
- **There is no authentication.** Upstream ChromaDB exposes an open HTTP API;
  anyone who can reach port 8141 can read and write collections. Keep it on a
  trusted LAN, or put a TLS reverse proxy with authentication in front of it
  before exposing it to the internet.
- The API is plain HTTP; terminate TLS on a reverse proxy for remote access.

## Store submission checklist

1. Public GitHub repository (this one: `Moechz/chromadb`).
2. Release **tag `v1.5.9-1`** with assets `chromadbdocker_x86_64.tar.gz`,
   `chromadbdocker_aarch64.tar.gz` and their `.sha256` files.
3. Developer platform: app `chromadbdocker`, package type Docker, one version
   `1.5.9-1` per architecture.
4. Submission remark: "Rectified per review comments" (C3/C4/C5/C6/C7/C8/C10,
   T1, F7, S11).

## Limitations

- No authentication by default (see above).
- ChromaDB is API-first: `/docs/` is an API console, not a management UI.
- No bundled embedding model and no UI for browsing collections; use the SDK or
  a client such as AnythingLLM.
- Upgrading from 0.6.x is a manual export/import (see above).

## License / branding

ChromaDB is distributed by Chroma Inc. and the Chroma contributors under
**Apache-2.0**. The container image is the official multi-arch image from
Docker Hub and is used unmodified; no upstream source code is redistributed
here. This packaging is an independent community submission by Moechz and is
not affiliated with the upstream project or TerraMaster. See
[`NOTICE.md`](NOTICE.md).

---

Packaged for TOS 7 by Moechz. Upstream image used unmodified from Docker Hub.
