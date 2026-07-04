# 🐾 Clem's Walk Schedule

A self-hosted single-file web app for managing Clementine's daily walk rota.

## Features

- **Infinite repeating 3-week cycle** — Dad, Mom, and Josh each walk exactly 7 times every 3 weeks
- **Dad evenings only** — morning slots are always Mom or Josh
- **No double-walks** — nobody walks Clem twice in one day
- **Unavailability overrides** — mark someone out for a morning, evening, full day, or date range; the schedule auto-reassigns
- **Click any slot** to quickly mark that walker unavailable
- **Persistent overrides** — stored server-side in `overrides.json`, shared by everyone on the network
- Zero dependencies beyond the Python standard library

## Running

Runs as a Docker container on `linuxvm` (see `AGENT.md` for the deploy commands). To run it standalone for local testing:

```bash
python3 server.py
```

Then browse to `https://localhost:8093`. Requires the TLS cert files referenced at the top of `server.py`.

## See also

`AGENT.md` for detailed notes on the schedule logic, deployment, and maintenance.
