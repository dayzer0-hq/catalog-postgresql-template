#!/usr/bin/env bash
# Tiny forward-only migration runner for the DayZer0 PostgreSQL starter.
#
# It applies every migrations/*.sql that has not been applied yet, in filename
# order, each inside its own transaction, and records it in a schema_migrations
# bookkeeping table. Re-running is a no-op — which is also the health check:
# with no migrations yet it still creates the table, connects, and reports
# "up to date", proving your PostgreSQL connection and this runner both work.
#
# Usage:  DATABASE_URL=postgres://localhost:5432/yourdb ./run_migrations.sh
set -euo pipefail

DATABASE_URL="${DATABASE_URL:-postgres://localhost:5432/postgres}"
MIG_DIR="$(cd "$(dirname "$0")" && pwd)/migrations"

psql_do() { psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -q "$@"; }

# Created once; idempotent. This line alone is the connection health check.
psql_do -c "CREATE TABLE IF NOT EXISTS schema_migrations (version text PRIMARY KEY, applied_at timestamptz NOT NULL DEFAULT now());"

applied=0
for f in "$MIG_DIR"/*.sql; do
  [ -e "$f" ] || continue                     # empty migrations/ -> nothing pending
  version="$(basename "$f")"
  # ponytail: version comes from a filename you control; it is interpolated into
  # a SQL literal. A filename with a single quote would break it — don't use one.
  already="$(psql_do -t -A -c "SELECT 1 FROM schema_migrations WHERE version = '$version';")"
  [ "$already" = "1" ] && continue
  echo "applying $version"
  # File and bookkeeping row commit together, so a failed migration records nothing.
  psql_do --single-transaction -f "$f" \
    -c "INSERT INTO schema_migrations (version) VALUES ('$version');"
  applied=$((applied + 1))
done

if [ "$applied" -eq 0 ]; then
  echo "up to date (0 pending)"
else
  echo "applied $applied migration(s)"
fi
