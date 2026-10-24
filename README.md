# Fastbreak

A Go and PostgreSQL API performance lab. Find the highest sustainable throughput
under explicit latency and error targets, then measure each optimization.

## Local database

Start Docker Desktop with the Linux container engine, then run:

```sh
docker compose up -d --wait
docker compose exec postgres psql -U fastbreak -d fastbreak -c "SELECT count(*) FROM nba.players;"
```

Connection string for the Go API:

```text
postgres://fastbreak:fastbreak_local@localhost:5433/fastbreak?sslmode=disable
```

These credentials are for local development. The database port binds to localhost.
The named volume persists database data. Initialization loads real 2021-22 NBA
regular-season and playoff data when the database volume is empty.

## NBA data

Source: [NocturneBear/NBA-Data-2010-2024](https://github.com/NocturneBear/NBA-Data-2010-2024),
a community archive, not a live official NBA API. `data/source.json` pins the source
commit, download URLs, file sizes, and SHA-256 hashes; `data/LICENSE.source` retains
the archive's MIT license. The normalized 2021-22 snapshot is in `data/2021-22`.

The dataset contains 30 teams, 620 player identities (including DNP entries),
1,317 games (1,230 regular season + 87 playoffs), 2,634 team-game rows, and 33,693
player-game rows. Play-in games are excluded. IDs are preserved from the archive;
game IDs retain their leading zeros. Player-game team membership handles trades.
Player points reconcile to team points for every game. All original stat fields
are retained in `source_record` JSONB, with common query fields stored in typed columns.

Tables: `nba.players`, `nba.teams`, `nba.games`, `nba.team_game_stats`,
and `nba.player_game_stats`. Synthetic rows are no longer seeded. If an older
volume contains `public.players`, it is left untouched; use the `nba` tables.

To reproduce the download and preparation (Python standard library only):

```sh
python scripts/fetch_nba.py
python scripts/prepare_nba.py
```

The fetch script resolves the source's current commit and records it. To import
into an already initialized volume, or safely rerun the import:

```sh
docker compose exec -T postgres psql -U fastbreak -d fastbreak -f /import/load.sql
docker compose exec -T postgres psql -U fastbreak -d fastbreak -f /import/verify.sql
```

Imports run in a transaction and upsert by stable IDs, so reruns do not duplicate
records. Do not delete the database volume to reimport.

Stop the database with `docker compose down`; this preserves its data.

## Experiment plan

1. Implement an uncached player-by-ID endpoint using net/http and pgxpool.
2. Establish a baseline with 1, 10, 50, 100, 250, and 500 concurrent clients.
3. Record requests/second, p50/p95/p99 latency, errors, CPU, memory, and pool waits.
4. Vary pool size, query shape, indexes, and response serialization one at a time.
5. Repeat promising settings and compare at the same workload and data size.

Initial target: p95 below 100 ms and errors below 1%; revise to match the use case.
Concurrent clients are not the same as requests/second or database connections.
Also use a fixed arrival-rate test to reveal queueing under overload.

Record the Go/Postgres versions, image digest, Docker CPU/RAM limits, OS, and
power mode for each run. On Windows, Docker Desktop's Linux VM and localhost
networking are part of the measured system. Keep resource settings stable.
Running the API, database, and load generator on one laptop introduces contention;
use a separate load-generator machine when measuring the server's ceiling.
