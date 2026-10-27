# Fastbreak learning plan

## Purpose

Learn Go's way of thinking, system design, high-load PostgreSQL, replication,
and distributed computing by building and measuring a basketball API.
The learner is experienced in Python. Work in small, explained steps.

## Current state

- Repository: https://github.com/pnivarthi/fastbreak (public).
- Local directory: C:\Users\Pranav\workspace\Tinker\fastbreak.
- Go 1.27.0 is installed on Windows; module: github.com/pnivarthi/fastbreak.
- main.go prints "Fastbreak". Both go run and a built executable were verified.
- No HTTP server, Go database driver, or load tests have been implemented yet.
- PostgreSQL runs through compose.yaml, exposed on localhost:5433 because 5432
  was already occupied. Check Docker's current state before assuming it is running.
- The database contains real 2021-22 regular-season and playoff data in the nba
  schema: 30 teams, 620 player identities, 1,317 games, 2,634 team-game records,
  and 33,693 player-game records. DNP entries are included; play-in games are not.
- README.md documents setup, provenance, imports, and validation. db/queries.sql
  includes Curry's Finals game log and regular-season scoring leaders.
- The initial dataset foundation was pushed to GitHub. Check git status before
  committing: the initial Go files and these learning documents may be uncommitted.

## Next lesson

Have the learner change the printed message and run the program. Explain
package main, imports, func main, go.mod, go run, and go build as needed.
Then introduce a minimal net/http server with a /healthz endpoint. Explain
handlers and the request/response lifecycle before connecting PostgreSQL.

## Roadmap

1. Go fundamentals: module, executable, functions, structs, errors, packages.
2. First API: net/http, JSON, PostgreSQL lookup using pgxpool.
3. Concurrency: goroutines, ownership, synchronization, context cancellation,
   timeouts, graceful shutdown, bounded connection pools, and backpressure.
4. Measurement: repeatable load tests, RPS, p50/p95/p99, errors, CPU, memory,
   profiling, and separating load-generator limits from server limits.
5. PostgreSQL: EXPLAIN ANALYZE, indexes, pagination, transactions, isolation,
   contention, and pool sizing. Change one variable at a time.
6. Replication: primary and replica, read routing, replication lag, stale reads,
   read-after-write consistency, and failure experiments.
7. Multiple API instances: load balancing, statelessness, cache placement,
   invalidation, coordination, and partial failure.
8. Distributed processing: a labeled simulated live-game feed, queues, retries,
   idempotency, delivery guarantees, and eventual consistency.

The 1M requests/second video is inspiration, not an established capacity target.
Define the work per request and latency/error targets before comparing results.
Multiple containers on one laptop can demonstrate distributed behavior; they
share physical resources and do not establish multi-machine scaling capacity.

## Learning loop

Predict what will happen, implement a small change, measure, and explain the
result. Add complexity when an experiment or explicit learning goal justifies it.

