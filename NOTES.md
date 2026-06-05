# Clem's Walk Schedule — Project Notes

## Overview

A self-hosted web app for managing Clementine's daily walk schedule.
Served from the Pi via a small Python server (`server.py`) that handles
static files and shared override storage.

## The Base Schedule

Three walkers: **Dad**, **Mom**, **Josh**.
- 2 walks per day: morning and evening
- Nobody walks twice in one day
- Dad does evenings only (not available for mornings)
- Perfectly equal over a **3-week repeating cycle** (7 walks each per cycle)

The base 3-week rotation is encoded in `index.html` as a JS array. Week 4 = Week 1, etc.

## How Unavailability Works

Overrides are stored server-side in `overrides.json` (next to `index.html`),
so all users on the local network share the same state. The page loads them
via `GET /overrides` on startup and writes back via `POST /overrides` after
each change.

Each override is an object:

```json
{
  "id": "uuid",
  "walker": "Dad" | "Mom" | "Josh",
  "type": "morning" | "evening" | "day" | "range",
  "startDate": "YYYY-MM-DD",
  "endDate": "YYYY-MM-DD"   // same as startDate for single day/slot
}
```

When an override is applied the schedule engine:
1. Finds every affected slot (morning and/or evening for each date in range)
2. Removes the unavailable walker from those slots
3. Reassigns using the next available walker in the rotation order (Mom → Josh → Dad[eve only])
   who isn't already walking that day and isn't also marked unavailable

## Adjusting the Base Rotation

If the household changes (new walker, walker leaves, Dad gets mornings back):
- Edit the `BASE_ROTATION` array near the top of the `<script>` block in `index.html`
- The array is 42 entries (21 days × 2 slots), cycling from Week 1 Monday morning

## Serving on the Pi

The app requires `server.py` — it can't be served as a plain static file because
overrides need a writable server-side endpoint.

```bash
# Run manually (port 8093)
cd ~/OneDrive/Dev/clem_schedule
python3 server.py
```

For the permanent systemd service:

```bash
bash install.sh   # installs/restarts clem-schedule.service on port 8093
```

Access at `http://<pi-ip>:8093` from any device on the local network.

## Maintenance

- Overrides persist in `overrides.json` on the Pi — shared by all users
- To back up overrides, copy `overrides.json` out of the install directory
- To fully reset, click "Clear all overrides" in the settings panel (or `echo '[]' > overrides.json`)

## Git / Deployment

```bash
git add -A && git commit -m "update schedule"
git push origin main
```
