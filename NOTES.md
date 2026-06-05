# Clem's Walk Schedule — Project Notes

## Overview

A self-hosted web app (single HTML file, no server required) for managing
Clementine's daily walk schedule. Served from this Pi.

## The Base Schedule

Three walkers: **Dad**, **Mom**, **Josh**.
- 2 walks per day: morning and evening
- Nobody walks twice in one day
- Dad does evenings only (not available for mornings)
- Perfectly equal over a **3-week repeating cycle** (7 walks each per cycle)

The base 3-week rotation is encoded in `index.html` as a JS array. Week 4 = Week 1, etc.

## How Unavailability Works

Overrides are stored in `localStorage` under the key `clemOverrides`.
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

No server needed — just open `index.html` in a browser, OR serve statically:

```bash
# Quick one-liner (Python must be installed)
cd ~/OneDrive/Dev/clem_schedule
python3 -m http.server 8080
```

Then access at `http://<pi-ip>:8080` from any device on the local network.

For a permanent service, add a systemd unit or drop it in nginx/lighttpd's webroot.

## Maintenance

- Overrides persist in the browser's localStorage on whatever device manages the schedule
- If moving to a new device, export overrides via the Export button on the page
- To fully reset, click "Clear all overrides" in the settings panel

## Git / Deployment

```bash
git add -A && git commit -m "update schedule"
git push origin main
```
