# Functional Requirements

Reference document for the Gleam implementation. Describes what the worker must do, not how.

## Request Handling

- Accept `GET` and `OPTIONS` requests only
- Respond to `OPTIONS` with CORS headers and no body (HTTP 200)
- All responses include CORS headers: `Access-Control-Allow-Origin: *`, `Access-Control-Allow-Methods: GET, OPTIONS`, `Access-Control-Allow-Headers: Content-Type`
- All responses (including errors) include an `outages` array

## Request Flow (Normal Mode)

1. Check for `?test=` query param — if present, enter test mode flow (see below)
2. Parse `?lat=` and `?lon=` query params as floats
3. Validate latitude (-90 to 90, finite number)
4. Validate longitude (-180 to 180, finite number)
5. Reject invalid/missing coordinates with HTTP 400
6. Validate coordinates are within BC service area (lat 48.3–60.0, lon -139.0 to -114.0)
7. Reject out-of-area coordinates with HTTP 400
8. Fetch outages from BC Hydro API (with server-side cache)
9. Filter outages by point-in-polygon (user coords vs outage polygon)
10. Return filtered outages with HTTP 200

## Test Mode Flow

Test mode is enabled when both:
- `TEST_MODE` env var equals `"true"`
- `?test=` query param is present

Valid `?test=` values: `outage`, `no-outage`, `multiple`

If `TEST_MODE=true` and `?test=` is present but invalid → HTTP 400 with error message.
If `TEST_MODE=false` and `?test=` is present → ignore, proceed with normal flow.
If test mode is valid → skip coordinate parsing/validation, use fixed Vancouver coords (49.2827, -123.1207), return mock data.

Test responses are never cached (`Cache-Control: no-cache`).
All mock outage data includes `(TEST DATA)` in the `cause` field.

## Caching

- Server-side cache key: `https://cache.bchydro-proxy.internal/outages`
- Cache TTL: `CACHE_MAX_AGE` env var (default 300 seconds)
- Cache hit → return raw JSON from cache, set `cached: true` in response
- Cache miss → fetch from BC Hydro, store raw JSON in cache, set `cached: false`
- Client cache header: `Cache-Control: public, max-age=N` where N = min(60, CACHE_MAX_AGE)
- Uses Cloudflare's `caches.default` API

## BC Hydro API

- URL: `https://www.bchydro.com/power-outages/app/outages-map-data.json`
- Method: `GET`
- Request header: `User-Agent: BCHydroProxy/1.0`
- Returns a JSON array of outage objects
- Non-2xx response → HTTP 500 with error message

## Point-in-Polygon

- Algorithm: ray casting
- Polygon format: flat `Float` array `[lon1, lat1, lon2, lat2, ...]`
- Minimum 3 points (6 coords), even number of coords, all finite floats
- Outages with missing or invalid polygons are excluded from results

## Response Shape (Success)

```json
{
  "cached": false,
  "coordinates": { "latitude": 49.2827, "longitude": -123.1207 },
  "totalOutages": 42,
  "affectingYou": 1,
  "outages": [
    {
      "id": "...",
      "municipality": "...",
      "area": "...",
      "cause": "...",
      "numCustomersOut": 1500,
      "crewStatus": "ONSITE",
      "crewStatusDescription": "...",
      "crewStatusDetail": "...",
      "dateOff": 1234567890000,
      "dateOn": 1234567890000,
      "lastUpdated": 1234567890000,
      "regionName": "...",
      "showEtr": true,
      "crewEtr": 1234567890000,
      "latitude": 49.2827,
      "longitude": -123.1207
    }
  ]
}
```

## Crew Status Codes → Detail

| Code | Meaning |
|---|---|
| `NOT_ASSIGNED` | No crew yet; may have been pulled for emergency |
| `ASSIGNED` | Crew assigned, on their list |
| `ENROUTE` | Crew on the way |
| `ONSITE` | Crew investigating, ETR coming soon |
| `SUSPENDED` | Crew needed different equipment/resources |

Unknown status → `crewStatusDetail` is `null`.

## Error Responses

All errors include `"outages": []`.

| Condition | Status | Message |
|---|---|---|
| Invalid/missing coords | 400 | `"Missing or invalid coordinates. Provide ?lat=XX.XXXX&lon=YY.YYYY query parameters"` |
| Outside BC area | 400 | `"Coordinates outside BC Hydro service area (British Columbia, Canada)"` |
| Invalid test param | 400 | `"Invalid test mode. Valid options: outage, no-outage, multiple"` |
| BC Hydro API error | 500 | `"BC Hydro API returned {status}"` |
| Unhandled exception | 500 | error message string |

## Environment Variables

| Variable | Default | Description |
|---|---|---|
| `CACHE_MAX_AGE` | `"300"` | Server-side cache TTL in seconds (string) |
| `TEST_MODE` | `"false"` | Enable test mode (`"true"` / `"false"` string) |

## Test Data Fixtures

Three test modes produce different mock outage sets, all using generic BC coordinates:

- `outage` — 1 outage, polygon covers downtown Vancouver (49.2827, -123.1207)
- `no-outage` — 1 outage in Victoria (48.4284, -123.3656), polygon does NOT cover Vancouver
- `multiple` — 3 outages: 2 covering Vancouver (different polygons), 1 in Kelowna (49.888, -119.496)
