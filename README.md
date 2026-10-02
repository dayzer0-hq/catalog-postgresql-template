# DayZer0 PostgreSQL starter

The starting point for the DayZer0 PostgreSQL briefs. The deliverable on these
boards **is the database work** — schema, constraints, indexes, queries and
transactions, authored as plain SQL migrations and reviewed as a pull request.
There is no web framework and no ORM; just PostgreSQL and SQL.

This repo gives you the plumbing so your first piece of work is the schema
itself, not the migration machinery:

- `run_migrations.sh` — a tiny forward-only migration runner (see below).
- `migrations/` — where your migrations live, one SQL file per step.
- `.github/PULL_REQUEST_TEMPLATE.md` — reminds you to link the issue you close.

## Requirements

- PostgreSQL 14 or newer (`psql --version`).
- A database you can connect to. Point `DATABASE_URL` at it:

```bash
cp .env.example .env        # then edit DATABASE_URL, or just export it
export DATABASE_URL=postgres://localhost:5432/dayzer0
```

## Run it

```bash
./run_migrations.sh
```

With no migrations yet it creates the `schema_migrations` bookkeeping table and
prints `up to date (0 pending)`. That round-trip to the database is your health
check: if it connects and prints that, the runner works and you can start.

## Writing a migration

Add a numbered SQL file to `migrations/`. They apply in filename order, so the
number is the order:

```
migrations/0001_menu.sql
migrations/0002_indexes.sql
```

Each run applies only the files not already recorded in `schema_migrations`,
each in its own transaction. Migrations are **forward-only** — write a new one
to change something, don't edit an applied file.

A `seed.sql` at the repo root (run it by hand with `psql "$DATABASE_URL" -f seed.sql`)
is the usual place for sample rows; keep it out of `migrations/` so it is not
tracked as schema.

## One ticket, one branch, one pull request

Each ticket on your board carries the exact branch name and the `Closes #N` to
put in the pull request. Never commit straight to `main`.
