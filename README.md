# London Climbing Centres — Opening Times

A single, unified webpage displaying the opening times for **all 8 London Climbing Centres** locations.

## Centres

| Centre | Location |
|---|---|
| VauxWall West | Vauxhall, South London |
| VauxWall East | Vauxhall, South London |
| HarroWall | Harrow, North West London |
| CroyWall | Croydon, South London |
| RavensWall | Ravenscourt Park, West London |
| CanaryWall | Canary Wharf, East London |
| BethWall | Bethnal Green, East London |
| EustonWall | Euston, Central London |

## Files

```
.
├── index.html          # Unified webpage with all 8 centres
├── sync-images.sh      # Script to check & update images weekly
├── images/             # Downloaded opening-times images (8 files)
└── .last-sync          # Timestamp of the most recent sync
```

## How it works

- Each centre's opening times are displayed as the **original image** from the [London Climbing Centres website](https://londonclimbingcentres.co.uk/). These images live in the `images/` directory.
- The **centre name** is clearly shown above each image, with a coloured left-border stripe and acronym badge using that centre's brand colour from the LCC website.
- `sync-images.sh` downloads each image, compares it (SHA256 hash) against the local copy, and replaces it only if the source has changed. It also updates the "Last synced" timestamp displayed on the webpage.

## Running the sync manually

```bash
# From the project directory:
bash sync-images.sh
```

You need `curl` and `sha256sum` (or `shasum` on macOS). Git Bash on Windows includes both.

## Scheduling weekly updates

### Linux / macOS (cron)

```bash
# Every Monday at 03:00
0 3 * * 1 /path/to/sync-images.sh
```

### Windows Task Scheduler

| Field | Value |
|---|---|
| **Program** | `bash` |
| **Arguments** | `/c path\to\sync-images.sh` |
| **Start in** | `path\to\` |
| **Schedule** | Weekly |

## Serving the page

The page is plain HTML + CSS (no build step). To view:

```bash
# Python
python3 -m http.server 8000

# Or just open index.html directly in a browser
```

Navigate to `http://localhost:8000` to see the page.

## Source

All opening-times images are sourced from:
https://londonclimbingcentres.co.uk/

Individual centre pages:
- https://londonclimbingcentres.co.uk/centre/vauxwest/
- https://londonclimbingcentres.co.uk/centre/vauxeast/
- https://londonclimbingcentres.co.uk/centre/harrowall/
- https://londonclimbingcentres.co.uk/centre/croywall/
- https://londonclimbingcentres.co.uk/centre/ravenswall/
- https://londonclimbingcentres.co.uk/centre/canarywall/
- https://londonclimbingcentres.co.uk/centre/bethwall/
- https://londonclimbingcentres.co.uk/centre/eustonwall/
