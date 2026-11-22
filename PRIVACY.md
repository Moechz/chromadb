# Privacy policy — ChromaDB for TerraMaster TOS (`chromadbdocker`)

**Last updated:** 2026-11-22
**Applies to:** ChromaDB package version `1.5.9-1` and later, published by Moechz in
the TerraMaster App Center.
**Upstream project:** <https://github.com/chroma-core/chroma>
**Contact / data requests:** <https://github.com/Moechz/chromadb/issues>

This policy explains what this application package stores, where it is stored,
how long it is kept, what leaves your NAS and when, and how you can access,
correct or delete your data.

ChromaDB is **self-hosted**. It runs entirely on your TerraMaster NAS inside a
Docker container. The packager does not operate a server, does not receive your
collections, documents, embeddings or queries, and has no way to access your
NAS. The "data controller" for the content you put into ChromaDB is you, the
owner/administrator of the NAS.

---

## 1. What the application stores

ChromaDB is a vector database; everything it holds is data **you** (or the
application that talks to it) write through the API:

| Data | Where it is stored | Why |
|---|---|---|
| Collections (name, id, configuration) | `/Volume1/DockerAppData/chromadbdocker/data/chroma.sqlite3` | The database catalog: which collections exist and how they are indexed. |
| Records: ids, embeddings (vectors), documents and metadata | same SQLite file | This is the data you insert with `add` / `upsert` / `update`. Documents and metadata may contain personal data if you put it there (for example names, e-mail addresses or free text). |
| Vector index segments | `.../data/<uuid>/*.bin` (`header.bin`, `data_level0.bin`, `length.bin`, `link_lists.bin`) | The HNSW index used for similarity search. Derived from your embeddings. |
| Server logs | Docker's log store for the container (stdout/stderr) | Operational messages: start-up banner, request errors, stack traces. They can contain the requested URL path, a collection id and client IP addresses. Kept on the NAS and rotated by your Docker logging configuration. |

The application does **not** create user accounts, does not ask for an e-mail
address, name or phone number, sets no cookies, ships no analytics or
advertising code, and contains no client-side tracking script. The API console
at `/docs/` is served entirely by the container itself: no font, stylesheet or
script is loaded from a CDN.

ChromaDB has no built-in authentication (see §9), so anyone who can reach the
port can read and write this data.

## 2. Where the data is stored

- **On the NAS (persistent):** `/Volume1/DockerAppData/chromadbdocker/data/`
  - `chroma.sqlite3` — catalog + records (ids, documents, metadata, embeddings)
  - `<uuid>/` — one directory per vector-index segment (`.bin` files)
- **Inside the container:** the same directory, bind-mounted at `/data`
  (`/config.yaml` in the image sets `persist_path: /data`).
- **Container root filesystem:** read-only. `/tmp` is a tmpfs that is discarded
  when the container stops. Your data is never written there.
- **In the image:** only the ChromaDB server binary and a minimal Debian
  userland.

Nothing is written to shared folders or to other applications' data
directories. File ownership is the application user `1000:1000`; the package
does not raise permissions on its files (no setuid, no world-writable paths).

**Upgrading from 0.6.x:** version 1.x uses a new storage layout. Data written by
a 0.6.x installation lives in `.../data/chroma/` (its own `chroma.sqlite3` plus
index directories). It is **left untouched** by 1.x, so nothing is destroyed by
the upgrade, but it is not read either. README.md documents how to export those
collections and re-insert them through the API, and how to roll back.

## 3. What leaves the NAS

**No user content leaves the NAS.** Documents, metadata, embeddings, queries
and collection names are never uploaded to the packager, to the upstream
project, or to any analytics service.

Only these network flows exist:

| # | When | Destination | Data sent |
|---|---|---|---|
| 1 | Installing or updating the app | Docker Hub (`registry-1.docker.io`, `auth.docker.io`, operated by Docker, Inc., United States) | The NAS's IP address and the requested image `chromadb/chroma:1.5.9`. This is the normal registry download that every Docker application performs. |
| 2 | Only if **you** turn upstream telemetry on (off in this package, see §4) | PostHog (`us.i.posthog.com`, PostHog, Inc., United States) | Anonymized usage events, listed in §4. Never your documents, metadata values, embeddings or queries. |
| 3 | Only if you attach a **hosted** embedding provider yourself (§5) | The provider you configure | Whatever that provider's API requires — by definition your text. This is not configured by the package. |

Everything else — the vector search, the SQLite writes, the index building —
happens locally in the container. There is no licence check, no "phone home" at
start-up, no crash reporting and no update ping: the server only prints its
banner and starts listening.

## 4. Upstream telemetry — disclosed and switched off

Upstream ChromaDB 0.6.x enabled **anonymized product telemetry by default**
(`anonymized_telemetry: True` in `chromadb/config.py`), sent to PostHog with a
project key compiled into the package. The events were `ServerStartEvent`,
`ClientStartEvent`, `CollectionAddEvent`, `CollectionCreateEvent`,
`CollectionQueryEvent` and similar, carrying: the event name, a random
installation UUID (stored in `~/.cache/chroma/telemetry_user_id`), the
collection UUID, record counts (`add_amount`, `batch_size`,
`with_documents` / `with_metadata` / `with_uris`) and a few whitelisted
settings (`chroma_api_impl`, `is_persistent`, `chroma_server_ssl_enabled`,
`chroma_server_api_default_path`). It did **not** carry documents, metadata
values, embeddings or queries.

This package handles that explicitly:

- The container is started with `ANONYMIZED_TELEMETRY=False`.
- ChromaDB 1.x (the version shipped here) contains no telemetry provider at
  all: at start-up it prints `No telemetry is configured.` and the 1.5.9 binary
  contains no PostHog client or endpoint. `ANONYMIZED_TELEMETRY=False` is kept
  as an explicit, auditable switch in `src/docker-compose.yml`.

So **this package sends no usage data anywhere.** Because the 1.5.9 image has
no telemetry provider, even changing the variable to `"True"` would transmit
nothing today; it is pinned to `False` so that the intent is explicit and
reviewable, and so that a future image which reintroduces a provider stays off
by default. If upstream ever restores telemetry, the data would be exactly the
list above — never your content — and you could keep it off with the same
variable. The packager receives nothing either way.

## 5. Embedding models and third-party AI APIs

ChromaDB stores vectors; it normally does **not** compute them. Embeddings are
produced by the client library on the machine that calls the API:

- With the Python/JS client's **default** embedding function, the client
  downloads the ONNX build of the `all-MiniLM-L6-v2` sentence-transformer once
  (`https://chroma-onnx-models.s3.amazonaws.com/all-MiniLM-L6-v2/onnx.tar.gz`,
  Amazon S3, United States) and runs it **locally** on your own computer. This
  happens on the client, not on the NAS, and the model file contains no data
  about you.
- If your client is configured with a **hosted** embedding provider (for
  example OpenAI, Cohere, Voyage AI or Jina), then that client sends your text
  to that provider. That transfer is between you and the provider you chose,
  under their privacy policy; it does not go through this package.
- This package ships **no** embedding function, no model download and no API
  key. The server-side `/api/v2/.../add` endpoint requires embeddings in the
  request body (verified: a request with only documents is rejected with
  `missing field 'embeddings'`), so the server itself never calls out to an
  embedding API.

The `chroma copy --to-cloud` command of the upstream CLI would copy a database
to Chroma Cloud (`trychroma.com`). It only runs when a user types it; this
package never invokes it.

## 6. Retention period

- **Your collections, records and indexes do not expire.** There is no TTL, no
  scheduled deletion and no automatic compaction that removes data. They stay
  in `/Volume1/DockerAppData/chromadbdocker/data/` until you delete them, the
  container's volume is removed, or the application data is deleted.
- **Logs** are retained according to your Docker daemon's log rotation; the
  package does not set an unlimited log policy.
- **`/tmp`** is a tmpfs and is discarded on every container restart.
- **Backups:** if you back up the NAS or the data folder, copies exist under
  your backup tool's retention rules. The package creates no backups itself.
- **Telemetry** (only if you opted in, §4): held by PostHog under its own
  retention policy; the packager has no access to it.

## 7. Your rights and how to exercise them

The data is on your own NAS and the packager never receives it, so you exercise
your rights directly:

- **Access / portability:** the whole database is a documented, open format —
  `chroma.sqlite3` plus index folders. Read it with the ChromaDB Python/JS
  client (GET/query endpoints), the `/docs/` console, or any SQLite tool. You
  can copy the data folder at any time.
- **Rectification:** update or upsert records through the API
  (`.../update`, `.../upsert`), or edit metadata in place.
- **Erasure:** see §8.
- **Restriction / objection:** stop the container (App Center → stop) to freeze
  all processing; keep telemetry `False` (§4); do not configure a hosted
  embedding provider (§5).
- **Complaint:** contact the packager through
  <https://github.com/Moechz/chromadb/issues>; you also have the right to
  contact your local data-protection authority.

ChromaDB makes no automated decisions about you and does not profile users.
If you are a NAS administrator serving other people's data, you are the
controller for that data and this policy describes the technical means you have.

## 8. Deletion channel

1. **Through the API** (recommended for individual collections): `DELETE
   /api/v2/tenants/default_tenant/databases/default_database/collections/{name}`
   removes the collection, its records and its index; or use the "Try it out"
   button on the same endpoint in the `/docs/` console.
2. **From the NAS:** delete `/Volume1/DockerAppData/chromadbdocker/data/` (or
   single `<uuid>/` index folders plus the matching rows) with the TOS File
   Manager or `rm` over SSH. To erase everything, delete the whole
   `/Volume1/DockerAppData/chromadbdocker/` folder.
3. **Uninstall with data removal:** in App Center, uninstall ChromaDB and
   choose to delete the application data. Uninstalling while keeping the data
   leaves the database on disk and it is reused if you reinstall.

Deletion is immediate; the package keeps no recycle bin, no shadow copy and no
off-site copy. Data may persist in NAS snapshots or backups until those are
rotated out under your own policy.

## 9. Security measures

- The container runs as the non-root user **`1000:1000`** with a **read-only
  root filesystem**, `cap_drop: [ALL]`, `no-new-privileges`, no `privileged`
  mode, no host networking and no Docker socket.
- The only writable paths are the mounted data directory and an in-memory
  `/tmp`.
- The image is pulled from Docker Hub by fixed tag (`chromadb/chroma:1.5.9`)
  and never `:latest`, so an unexpected upstream change cannot silently alter
  the running service.
- Only the API port (container 8000) is published; the health check reads
  `/api/v2/heartbeat`.

**Deliberate limitation — no authentication.** Upstream ChromaDB 0.6.x and 1.x
expose an unauthenticated API; this package does not add a password because a
wrapper-level proxy would change the API surface that Chroma's own clients
expect. Treat the port like a shared folder:

- keep the app on a trusted LAN, or reach it through a VPN;
- before exposing it to the internet, put a TLS reverse proxy with
  authentication (basic auth, OAuth2 proxy, …) in front of it and do not
  publish port 8141 directly;
- the API is plain HTTP in this package, so a TLS terminator is also needed for
  confidentiality.

If you find a vulnerability in the packaging, report it through
<https://github.com/Moechz/chromadb/issues>.

## 10. Third-party sharing and components

The packager does not sell, rent or share personal data, and never receives any.
The application only contacts a third party in the cases listed in §3.

The container image is the official upstream image, used unmodified. It
contains ChromaDB (Apache-2.0), a Rust runtime and a minimal Debian GNU/Linux
userland. Their licences and copyright notices are listed in
[`NOTICE.md`](NOTICE.md); no upstream source code is modified or redistributed
in this repository.

## 11. Children

ChromaDB is a general-purpose database component for administrators. It is not
directed at children, and the packager collects no data at all — not from
children and not from anyone else.

## 12. Changes to this policy

This policy is versioned together with the application in the public repository
<https://github.com/Moechz/chromadb>. Material changes are described in
[`CHANGELOG.md`](CHANGELOG.md). The current version is always available at:

<https://github.com/Moechz/chromadb/blob/main/PRIVACY.md>

The package's `help` link (App Center → ChromaDB → Help) points to this
document, so it opens directly from the application.
