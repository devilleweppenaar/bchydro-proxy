# BC Hydro Outage Proxy

A Cloudflare Worker that checks if BC Hydro power outages affect your specific location.

## What It Does

- Fetches BC Hydro outage data
- Filters outages using point-in-polygon detection
- Returns only outages affecting YOUR coordinates
- Caches results for 5 minutes to reduce API calls

## Setup

### 1. Deploy to Cloudflare

Push this repo to GitHub. Cloudflare Workers will auto-deploy when connected.

### 2. Set Your Coordinates

In Cloudflare Dashboard:
1. Go to: **Workers & Pages** > **bchydro-proxy** > **Settings** > **Variables**
2. Add two encrypted secrets:
   - `LATITUDE`: Your latitude (e.g., `49.2827`)
   - `LONGITUDE`: Your longitude (e.g., `-123.1207`)
3. Click **Encrypt** for each secret

**Optional**: Adjust cache duration (default is 300 seconds / 5 minutes):
- Add a plain text variable: `CACHE_MAX_AGE` (e.g., `600` for 10 minutes)
- Don't encrypt this one - it's not sensitive

### 3. Test It

```bash
curl https://your-worker.workers.dev/
```

## Response Format

### No Outage
```json
{
  "cached": true,
  "coordinates": {
    "latitude": 49.2827,
    "longitude": -123.1207
  },
  "totalOutages": 14,
  "affectingYou": 0,
  "outages": []
}
```

### Outage Detected
```json
{
  "cached": false,
  "coordinates": {
    "latitude": 49.2827,
    "longitude": -123.1207
  },
  "totalOutages": 15,
  "affectingYou": 1,
  "outages": [
    {
      "id": 2681104,
      "municipality": "Vancouver",
      "area": "1200 block Example St",
      "cause": "Tree down across our wires",
      "numCustomersOut": 245,
      "crewStatus": "ONSITE",
      "crewStatusDescription": "Crew on-site",
      "crewStatusDetail": "A crew is working to investigate the cause...",
      "dateOff": 1733515200000,
      "dateOn": 1733522400000,
      "crewEtr": 1733522400000,
      "latitude": 49.2827,
      "longitude": -123.1207
    }
  ]
}
```

## Key Fields

- `cached`: `true` if served from cache (< 5 min old), `false` if fresh from BC Hydro
- `affectingYou`: Number of outages at your location
- `totalOutages`: Total outages across BC
- `crewStatusDetail`: Human-readable crew status explanation

## Crew Status Meanings

- **NOT_ASSIGNED**: No crew assigned yet
- **ASSIGNED**: Crew assigned, on their list
- **ENROUTE**: Crew on their way
- **ONSITE**: Crew working on-site
- **SUSPENDED**: Needs different equipment

## Use with Apple Shortcuts

```
Get contents of [your-worker-url]
If [affectingYou] > 0:
    Show notification "Power outage detected!"
```

## How Caching Works

The worker uses **Cloudflare's Cache API** (built into Workers, no UI config needed):

- **Server cache**: Configurable via `CACHE_MAX_AGE` env var (default: 300 seconds / 5 minutes)
- **Client cache**: 1 minute - reduces calls to your worker
- **`cached` field**: Shows if response came from cache

First request: `cached: false` (fetches fresh data)  
Next requests (within cache period): `cached: true` (serves from cache)

**To change cache duration**: Set `CACHE_MAX_AGE` variable in Cloudflare Dashboard (in seconds)

## Privacy

- Your coordinates are encrypted Cloudflare secrets
- Not visible in code or logs
- Only filtered results are returned (not all BC outages)

## Files

- `worker.js` - Main worker code
- `wrangler.toml` - Cloudflare configuration
- `.dev.vars` - Local development secrets (gitignored)
- `.gitignore` - Keeps secrets out of git

## License

See LICENSE file.