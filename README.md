# Fastbreak

**Learn Go. Query real NBA data. Measure every optimization.**

Fastbreak is a hands-on Go and PostgreSQL learning project that grows from a
small executable into a measured basketball API, then explores concurrency,
database performance, replication, and distributed systems.

The approach is simple: **predict → implement → measure → explain**.

## Where things stand

- **Ready:** a minimal Go executable and a reproducible PostgreSQL dataset.
- **Next:** a standard-library HTTP server with a `/healthz` endpoint.
- **Later:** JSON endpoints, database lookups, load testing, and replication.

The current program prints `Fastbreak`. HTTP endpoints and benchmark results
have not been implemented yet. Follow [LEARNING.md](LEARNING.md) for the lesson
plan and progress.

## Run the Go program

Install Go 1.27.0 or newer, then run from the repository root:

```sh
go run .
```

Expected output:

```text
Fastbreak
```

To build an executable on Windows:

```powershell
go build -o bin/fastbreak.exe .
.\bin\fastbreak.exe
```

The Go program currently needs no database or third-party Go dependencies.

## Start the database

With Docker Desktop running its Linux container engine:

```sh
docker compose up -d --wait
docker compose exec postgres psql -U fastbreak -d fastbreak -c "SELECT count(*) FROM nba.players;"
```

The query should return **620** players. PostgreSQL is exposed on localhost port
**5433** to avoid conflicting with an existing database on port 5432.

```text
postgres://fastbreak:<local-password>@localhost:5433/fastbreak?sslmode=disable
```

Use the local development password configured in `compose.yaml`. The port binds only to localhost;
this configuration is intended for local learning. The named volume preserves
data between restarts. Initialization imports the dataset when the volume is empty.

```sh
docker compose down
```

This stops the database and preserves its data.

## Real NBA data

The checked-in snapshot covers the **2021–22 regular season and playoffs**.

| Records | Count |
| --- | ---: |
| Teams | 30 |
| Player identities, including DNP entries | 620 |
| Regular-season games | 1,230 |
| Playoff games | 87 |
| Team-game records | 2,634 |
| Player-game records | 33,693 |

Play-in games are excluded. Player points reconcile to team points for every
game. Player-game team membership handles trades, and game IDs retain leading
zeros. Original stat fields are retained in `source_record` JSONB alongside
commonly queried typed columns.

Source: [NocturneBear/NBA-Data-2010-2024](https://github.com/NocturneBear/NBA-Data-2010-2024),
a community archive rather than a live official NBA API.
[data/source.json](data/source.json) records the source commit, URLs, sizes, and
SHA-256 hashes. The archive's MIT license is retained in
[data/LICENSE.source](data/LICENSE.source); it applies to the sourced material.

Tables live in the `nba` schema: `players`, `teams`, `games`, `team_game_stats`,
and `player_game_stats`. [db/queries.sql](db/queries.sql) includes Curry's Finals
game log and regular-season scoring leaders.

### Reproduce and validate the import

The preparation scripts use only the Python standard library:

```sh
python scripts/fetch_nba.py
python scripts/prepare_nba.py
```

The fetch script resolves the source's current commit and records it; a future
fetch may therefore use a newer source revision than the checked-in snapshot.

To import into an existing database and validate it:

```sh
docker compose exec -T postgres psql -U fastbreak -d fastbreak -f /import/load.sql
docker compose exec -T postgres psql -U fastbreak -d fastbreak -f /import/verify.sql
```

Imports run in a transaction and upsert by stable IDs, so reruns do not duplicate
records. There is no need to delete the database volume. Older installations
may still contain `public.players`; use the real data in the `nba` schema.

## Learning roadmap

1. **Go fundamentals** — modules, functions, structs, errors, and packages.
2. **First API** — `net/http`, JSON, and PostgreSQL lookups with `pgxpool`.
3. **Concurrency** — goroutines, cancellation, timeouts, and bounded pools.
4. **Measurement** — repeatable load tests, latency distributions, and profiling.
5. **Database performance** — query plans, indexes, transactions, and contention.
6. **Replication** — read routing, lag, consistency, and failure experiments.
7. **Multiple instances** — load balancing, caching, and coordination.
8. **Distributed processing** — a clearly labeled simulated feed, queues,
   retries, and idempotency.

## Performance experiments

Start with an uncached player-by-ID endpoint. Establish a baseline with 1, 10,
50, 100, 250, and 500 concurrent clients, then change one variable at a time.

Track throughput, p50/p95/p99 latency, errors, CPU, memory, and connection-pool
waits. An initial experimental target is p95 below 100 ms and errors below 1%;
these are proposed goals, not measured results. Include fixed arrival-rate tests
to expose queueing under overload.

Record Go/PostgreSQL versions, container image digest, CPU/RAM limits, OS, and
power mode. On Windows, Docker Desktop's Linux VM and localhost networking are
part of the measured system. A load generator on the same laptop competes for
resources; use a separate machine when measuring the server's ceiling.

## Project layout

```text
main.go          Go executable; HTTP server is the next lesson
go.mod           Module identity and minimum Go version
compose.yaml     Local PostgreSQL service
db/              Schema, import, validation, and example queries
data/2021-22/    Normalized real NBA snapshot
data/source.json Source provenance and checksums
scripts/         Python download and preparation tools
LEARNING.md      Detailed roadmap and lesson progress
```

