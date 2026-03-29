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
  "summary": "There is an outage in your area. Power has been out for about 2 hours due to equipment failure. A crew is on site. Power is expected to be restored in about 30 minutes.",
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

## Summary Field

Every successful `200` response includes a top-level `summary` string. It is a single natural language sentence (or short paragraph) suitable for direct display on a mobile screen or readout by a voice assistant (e.g. Siri). Error responses do not include `summary`.

The summary is generated from the outages affecting the queried location (`affectingYou`), not the full outage list.

### Scenarios

| Condition | Summary |
|---|---|
| No outages | `"There are no outages in your area."` |
| One outage | `"There is an outage in your area. Power has been out for about {duration}[ due to {cause}]. {crew sentence} {ETR sentence}"` |
| Multiple outages | `"There are {n} outages in your area. The most significant has been out for about {duration}[ due to {cause}]. {crew sentence} {ETR sentence}"` |

For multiple outages, the most significant is the one with the highest `numCustomersOut`.

### Duration Format

Durations use natural phrasing relative to the current time. No clock times are included.

- Less than 60 seconds → `"less than a minute"`
- 1–59 minutes → `"about {n} minute(s)"`
- Exact hours → `"about {n} hour(s)"`
- Hours with remainder → `"about {n} hour(s) and {m} minute(s)"`
- 1+ days → `"about {n} day(s)"`

The word `"about"` is omitted for the `"less than a minute"` case.

### Crew Sentences

| Status code | Sentence |
|---|---|
| `NOT_ASSIGNED` | `"No crew has been assigned yet."` |
| `ASSIGNED` | `"A crew has been assigned."` |
| `ENROUTE` | `"A crew is on their way."` |
| `ONSITE` | `"A crew is on site."` |
| `SUSPENDED` | `"The repair is currently suspended."` |

Unknown status code → crew sentence is omitted.

### ETR Sentences

ETR is shown only when `showEtr` is `true` and `crewEtr` is non-null. In all other cases (including `showEtr: false` or `crewEtr: null`), the no-ETR phrase is used.

| Condition | Sentence |
|---|---|
| ETR available and in the future | `"Power is expected to be restored in {duration}."` |
| ETR timestamp is in the past | `"Power restoration was expected but may have been delayed."` |
| No ETR available | `"There is no estimated restoration time yet."` |

### Cause Phrases

Known BC Hydro cause strings are mapped to natural phrases and integrated as `"due to {phrase}"`. Unknown cause strings are appended as a separate sentence: `"The cause is listed as: {lowercase string}."` The causes `"Other"` and `"Under investigation"` are silently omitted.

| Cause string | Phrase |
|---|---|
| `Bird contacting our wires` | `a bird contacting the lines` |
| `Cable fault` | `a cable fault` |
| `Customer's equipment` | `a customer's equipment issue` |
| `Equipment failure` | `equipment failure` |
| `Equipment contact` | `equipment contact` |
| `Fire` | `a fire` |
| `Motor vehicle accident` | `a motor vehicle accident` |
| `Mud or snow slide` | `a mud or snow slide` |
| `Object on our wires` | `an object on the lines` |
| `Pole down` | `a downed pole` |
| `Snow storm` | `a snow storm` |
| `Substation fault` | `a substation fault` |
| `Transformer burn out` | `a transformer burnout` |
| `Transmission circuit failure` | `a transmission circuit failure` |
| `Tree down across our wires` | `a downed tree on the lines` |
| `Vandalism` | `vandalism` |
| `Voltage Problem or Overload` | `a voltage problem or overload` |
| `Wind storm` | `a wind storm` |
| `Wire down` | `a downed wire` |
| `Construction` | `construction work` |
| `Planned work being done on our equipment` | `planned maintenance` |
| `Pole replacement` | `a pole replacement` |
| `Transformer replacement` | `a transformer replacement` |
| `Work being done on our equipment` | `maintenance work` |

Matching is case-insensitive.

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
