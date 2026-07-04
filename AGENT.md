# AGENT.md

Guidance for AI coding agents working in this repository. `README.md` covers
features from a user's perspective; this file covers architecture, deployment,
and maintenance.

## Overview

A self-hosted web app for managing Clementine's daily walk schedule. Served via
a small stdlib-only Python server (`server.py`) that handles static files and
shared override storage. Runs on `linuxvm` as a Docker container.

## The Base Schedule

Three walkers: **Dad**, **Mom**, **Josh**.
- 2 walks per day: morning and evening
- Nobody walks twice in one day unless there's no alternative
- Dad does all weekend mornings (Sat + Sun) + weekday evenings
- Dad can cover weekday mornings as a last resort (see below)
- Perfectly equal over a **3-week repeating cycle** (14 walks each per cycle)

The base 3-week rotation is encoded in `index.html` as a JS array (`BASE_ROTATION`,
42 entries = 21 days × 2 slots, cycling from Week 1 Monday morning). Week 4 = Week 1,
etc. There is no build step or bundler — `index.html` is copied into the image as-is.

## Overrides

Overrides are stored server-side in `overrides.json` (next to `index.html`), so all
users on the local network share the same state. The page loads them via
`GET /overrides` on startup and writes back via `POST /overrides` after each change.
`overrides.json` is bind-mounted into the container (not baked into the image), so
edits persist across rebuilds.

Two kinds of override:

### Unavailability (main panel)

Marks a walker as out for a period.

```json
{
  "id": "uuid",
  "walker": "Dad" | "Mom" | "Josh",
  "type": "morning" | "evening" | "day" | "range",
  "startDate": "YYYY-MM-DD",
  "endDate": "YYYY-MM-DD"
}
```

Multiple walkers can be out simultaneously — one override per person. The engine
collects all unavailable walkers before resolving each slot, so e.g. Mom and Dad
both away for a week correctly hands everything to Josh.

When an override is applied the schedule engine:
1. Finds every affected slot (morning and/or evening for each date in range)
2. Removes the unavailable walker from those slots
3. Reassigns to the first available walker in pool order who isn't already
   walking that day and isn't also marked unavailable
4. Falls back to double-walks (same person AM + PM) if no one else is free

### Direct slot assignment (slot picker)

Click any slot in the grid to assign a specific person, bypassing the rotation
entirely for that slot.

```json
{
  "id": "uuid",
  "type": "assign",
  "slot": "morning" | "evening",
  "walker": "Dad" | "Mom" | "Josh" | "SGW",
  "startDate": "YYYY-MM-DD",
  "endDate": "YYYY-MM-DD"
}
```

Direct assignments take priority over everything else — unavailability overrides
and reflow don't affect an explicitly assigned slot. "Reset to rotation default" in
the picker removes the assignment.

## Special Guest Walker (SGW)

A guest walker can be assigned to any slot via the slot picker (purple "Guest"
chip). The regular walker for that slot is freed and treated as available for
other slots that day when the engine resolves covers. SGW is only available in
the slot picker, not the main override panel.

## Dad on Mornings

Dad takes all weekend mornings. On weekends the full three-person pool is used
for morning cover, so Dad is a normal fallback alongside Mom and Josh.

On weekdays Dad is last resort for mornings. If both Mom and Josh are
unavailable, Dad is drafted, but a confirmation dialog ("Has Dad agreed to
this?") fires first. Once Mom or Josh becomes available again, Dad automatically
drops back off weekday mornings. The consent dialog does not fire for weekend
mornings.

## Files

- `index.html` — entire frontend: markup, styles, and the schedule engine (JS)
- `server.py` — stdlib-only HTTPS server; serves static files and the
  `overrides.json` read/write endpoints
- `overrides.json` — server-side persisted state, bind-mounted (not in the image)
- `pi-menu-card.html` — small link card embedded elsewhere, points at the deployed URL
- `clem_thumb.jpg` — thumbnail used by `pi-menu-card.html`

## Local Development

```bash
python3 server.py
```

Requires the TLS cert files referenced at the top of `server.py`. Browse to
`https://localhost:8093`.

## Build & Deploy

Source lives in place at `~/dev/clem_schedule` — the compose build context in
`/home/ben/docker/compose.yml` points directly at this directory, so there's no
separate copy/deploy step. Dockerfile lives at
`/home/ben/docker/clem-schedule/Dockerfile`.

```bash
cd /home/ben/docker
docker compose build clem-schedule
docker compose up -d clem-schedule
```

Runs as container `clem-schedule`, published on `8093`. Access at
`https://linuxvm.bearonatinybike.com:8093` from any device on the local network.
TLS uses the Let's Encrypt cert at `/etc/ssl/letsencrypt/` (bind-mounted read-only).
The renewal hook at `/etc/letsencrypt/renewal-hooks/deploy/copy-certs.sh` restarts
the container automatically on renewal — no manual action needed.

No fallback/native deployment path — Docker is the only supported way to run this
in production.

## Maintenance

- Overrides persist in `overrides.json` on the host, bind-mounted into the
  container — shared by all users
- To back up overrides, copy `overrides.json` out of `~/dev/clem_schedule`
- To fully reset, click "Clear all overrides" in the settings panel (or
  `echo '[]' > overrides.json`)

## Git / Deployment

```bash
git add -A && git commit -m "update"
git push
# On linuxvm (source and deployment are the same host):
cd ~/dev/clem_schedule && git pull
cd /home/ben/docker && docker compose build clem-schedule && docker compose up -d clem-schedule
```
