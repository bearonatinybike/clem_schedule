# Clem's Walk Schedule — Project Notes

## Overview

A self-hosted web app for managing Clementine's daily walk schedule.
Served from the Pi via a small Python server (`server.py`) that handles
static files and shared override storage.

## The Base Schedule

Three walkers: **Dad**, **Mom**, **Josh**.
- 2 walks per day: morning and evening
- Nobody walks twice in one day unless there's no alternative
- Dad does all weekend mornings (Sat + Sun) + weekday evenings
- Dad can cover weekday mornings as a last resort (see below)
- Perfectly equal over a **3-week repeating cycle** (14 walks each per cycle)

The base 3-week rotation is encoded in `index.html` as a JS array. Week 4 = Week 1, etc.

## Overrides

Overrides are stored server-side in `overrides.json` (next to `index.html`),
so all users on the local network share the same state. The page loads them
via `GET /overrides` on startup and writes back via `POST /overrides` after
each change.

There are two kinds of override:

### Unavailability (main panel)

Marks a walker as out for a period. Use "Add override" to set these.

```json
{
  "id": "uuid",
  "walker": "Dad" | "Mom" | "Josh",
  "type": "morning" | "evening" | "day" | "range",
  "startDate": "YYYY-MM-DD",
  "endDate": "YYYY-MM-DD"
}
```

Multiple walkers can be out simultaneously — add one override per person.
The engine collects all unavailable walkers before resolving each slot, so
e.g. Mom and Dad both away for a week will correctly hand everything to Josh.

When an override is applied the schedule engine:
1. Finds every affected slot (morning and/or evening for each date in range)
2. Removes the unavailable walker from those slots
3. Reassigns to the first available walker in pool order who isn't already
   walking that day and isn't also marked unavailable
4. Falls back to double-walks (same person AM + PM) if no one else is free

### Direct slot assignment (slot picker)

Click any slot in the grid to open a simple picker and assign a specific
person to that slot on that day. Bypasses the rotation entirely for that slot.

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
and reflow don't affect an explicitly assigned slot. "Reset to rotation default"
in the picker removes the assignment.

## Special Guest Walker (SGW)

A guest walker can be assigned to any slot via the slot picker. The slot shows
as "Guest" (purple chip). The regular walker for that slot is freed and treated
as available for other slots that day when the engine is resolving covers.

SGW is only available in the slot picker, not the main override panel.

## Dad on Mornings

Dad takes all weekend mornings (every Saturday and Sunday).
On weekends the full three-person pool is used for morning cover, so Dad is a
normal fallback alongside Mom and Josh.

On weekdays Dad is still last resort for mornings. If both Mom and Josh are
unavailable, Dad is drafted, but a confirmation dialog — "Has Dad agreed to
this?" — fires first. Once Mom or Josh becomes available again, Dad automatically
drops back off weekday mornings. The consent dialog does not fire for weekend
mornings.

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

Access at `https://pi.bearonatinybike.com:8093` from any device on the local network.
TLS uses the Let's Encrypt cert at `/etc/ssl/letsencrypt/`. The cert renewal hook
at `/etc/letsencrypt/renewal-hooks/deploy/copy-certs.sh` restarts the service
automatically on renewal.

## Maintenance

- Overrides persist in `overrides.json` on the Pi — shared by all users
- To back up overrides, copy `overrides.json` out of the install directory
- To fully reset, click "Clear all overrides" in the settings panel (or `echo '[]' > overrides.json`)

## Git / Deployment

```bash
git add -A && git commit -m "update"
git push
# On the Pi:
cd ~/OneDrive/Dev/clem_schedule && git pull && sudo systemctl restart clem-schedule
```
