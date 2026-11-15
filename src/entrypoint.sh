#!/bin/sh
# ===========================================================================
# ChromaDB entrypoint for a non-root container (TOS 7 requirement).
#
# The image starts uvicorn from /chroma and its log config writes "chroma.log"
# into the current directory, which is read-only for uid 1000. This wrapper runs
# the server from the mounted data folder with PYTHONPATH pointing at the code,
# and keeps the persisted collections in /data/chroma.
# ===========================================================================
set -e
set -u

DATA=/data
mkdir -p "$DATA" 2>/dev/null || true

if ! ( : > "$DATA/.write-test" ) 2>/dev/null; then
  echo "chromadb: $DATA is not writable by uid $(id -u)" >&2
  exit 1
fi
rm -f "$DATA/.write-test"

export IS_PERSISTENT=1
export PYTHONPATH=/chroma
export CHROMA_PERSIST_DIRECTORY="$DATA/chroma"

cd "$DATA"
exec uvicorn chromadb.app:app \
  --workers 1 \
  --host 0.0.0.0 \
  --port 8000 \
  --proxy-headers \
  --log-config /chroma/chromadb/log_config.yml \
  --timeout-keep-alive 30
