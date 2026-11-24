# HMC · Hostel Management System

A PostgreSQL database and a read-only operations dashboard for hostel rooms, complaints, and fees. The 19-table schema also tracks staff roles, guest stays, parcels, overnight leave, and attendance. The demo deliberately gives North and South a room 101 so that room assignments and occupancy reports can be checked against a realistic edge case.

## Run the demo

Use PostgreSQL 15 or later with the `psql` client and a local role that can create a database. Node.js 22 or later runs the web dashboard.

```sh
export PGHOST=127.0.0.1
export PGDATABASE=hmc_demo
createdb "$PGDATABASE"
psql -X -v ON_ERROR_STOP=1 -f db/install.sql
psql -X -v ON_ERROR_STOP=1 -f db/reports.sql
```

Set `PGUSER` and `PGPORT` if your installation uses a different role or port. An existing database with no `hmc` schema also works. The installer creates the schema and loads fictional records in one transaction. Re-running it against an existing `hmc` schema stops before changing its contents.

In the same shell, start the dashboard.

```sh
cd app
npm ci
npm start
```

Open [the dashboard](http://127.0.0.1:3000). Express serves the reporting API and React renders the dashboard on the server. Use `DATABASE_URL` to point the app at another PostgreSQL connection, or pass the usual PostgreSQL environment variables.

## Reporting API

| Endpoint | Returns |
| --- | --- |
| `GET /api/occupancy` | One row per wing and room, with capacity, occupied student beds, vacant beds, and allocation status |
| `GET /api/complaints` | Complaint ID, category, status, date reported, and resolution date |
| `GET /api/payments` | Payment count and INR collected per month and payer type. Amounts are decimal strings. |

In the fixture, North 101 has two occupied beds out of two. South 101 has one out of three. Only active student assignments count toward resident occupancy. Visitor stays have separate records. A room can have unoccupied beds and still be closed for allocation.

## Database and reports

- [Schema](db/schema.sql) and [fictional demo data](db/seed.sql)
- [All 29 SQL reports](db/reports.sql) and [printable query catalog](docs/report-catalog.pdf)
- [Entity–relationship diagram](docs/er-diagram.pdf) and [relational diagram](docs/relational-diagram.pdf)
- [Normalization proofs](docs/normalization-proofs.pdf) and [notes on the executable schema](docs/source-notes.md)

## Verification

From the repository root, with the demo database loaded and Python 3.9 or later available:

```sh
psql -X -v ON_ERROR_STOP=1 -f tests/integrity.sql
python3 tests/reports.py
(cd app && npm test)
```

The SQL checks run inside a transaction and roll back their test changes. The report tests exercise the actual catalog queries. HTTP integration tests start an ephemeral server connected to the fixture. GitHub Actions repeats the installation and checks against PostgreSQL 16 on each pull request and on `main`.

Maintained by Shivam Thanki.
