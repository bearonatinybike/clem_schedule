# 🐾 Clem's Walk Schedule

A self-hosted single-file web app for managing Clementine's daily walk rota.

## Features

- **Infinite repeating 3-week cycle** — Dad, Mom, and Josh each walk exactly 7 times every 3 weeks
- **Dad evenings only** — morning slots are always Mom or Josh
- **No double-walks** — nobody walks Clem twice in one day
- **Unavailability overrides** — mark someone out for a morning, evening, full day, or date range; the schedule auto-reassigns
- **Click any slot** to quickly mark that walker unavailable
- **Persistent overrides** — stored in browser localStorage
- Zero dependencies, no server required

## Running on the Pi

```bash
cd ~/OneDrive/Dev/clem_schedule
python3 -m http.server 8080
```

Then browse to `http://<your-pi-ip>:8080` from any device on the network.

For a permanent service, add to crontab or create a systemd unit.

## See also

`NOTES.md` for detailed notes on the schedule logic and maintenance.
