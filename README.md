# BC Hydro Proxy

A Cloudflare Worker that checks for BC Hydro power outages at your location. Send it your coordinates and it returns a plain-language summary along with structured outage data.

## Usage

```
GET /?lat={latitude}&lon={longitude}
```

### Getting Your Coordinates

You can get your coordinates from Google Maps or Apple Maps by searching for your address and viewing the location details.

### Query Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `lat` | Yes | Latitude (decimal degrees) |
| `lon` | Yes | Longitude (decimal degrees) |
| `test` | No | Test scenario — see [Test Mode](#test-mode) |

### Example Request

```bash
curl "https://your-worker.example.com/?lat=49.2827&lon=-123.1207" | jq .
```

### Example Response

```json
{
  "summary": "There is an outage in your area. Power has been out for about 2 hours due to equipment failure. A crew is on site. Power is expected to be restored in about 30 minutes.",
  "cached": false,
  "coordinates": {
    "latitude": 49.2827,
    "longitude": -123.1207
  },
  "totalOutages": 42,
  "affectingYou": 1,
  "outages": [
    {
      "id": "12345",
      "municipality": "Vancouver",
      "area": "Downtown",
      "cause": "Equipment failure",
      "numCustomersOut": 1500,
      "crewStatus": "ONSITE",
      "crewStatusDescription": "Crew on-site",
      "crewStatusDetail": "Crew members are on site and investigating the problem.",
      "dateOff": 1234567890000,
      "dateOn": 1234567890000,
      "lastUpdated": 1234567890000,
      "regionName": "Lower Mainland",
      "showEtr": true,
      "crewEtr": 1234567890000,
      "latitude": 49.283,
      "longitude": -123.121
    }
  ]
}
```

The `summary` field is a plain-language description suitable for display or voice readout. Timestamps are Unix milliseconds. When there are no outages at your location, `affectingYou` is `0` and `outages` is empty.

## Error Responses

All error responses include an `outages` array.

**Missing or invalid coordinates** (400):
```json
{ "error": "Your coordinates are missing or invalid. Latitude and longitude are required.", "outages": [] }
```

**Outside BC service area** (400):
```json
{ "error": "Your coordinates are outside the BC Hydro service area.", "outages": [] }
```

**Service error** (500):
```json
{ "error": "The BC Hydro outage service returned an error.", "outages": [] }
```

## Test Mode

Test mode lets you simulate outage scenarios without waiting for a real outage. It requires `TEST_MODE=true` to be set on the worker (enabled by default in local development).

Use the `test` query parameter:

| Value | Description |
|-------|-------------|
| `outage` | One outage affecting your coordinates |
| `no-outage` | One outage elsewhere in BC, not affecting you |
| `multiple` | Three outages — two affecting you, one elsewhere |
| `error` | Simulated service error |

```bash
curl "http://localhost:8787/?lat=49.2827&lon=-123.1207&test=outage"
```

Test responses are never cached. The `summary` and `error` fields in test responses begin with `"This is a test."`.

## Caching

Outage data is cached server-side for up to 5 minutes (configurable via `CACHE_MAX_AGE`). The `cached` field in the response indicates whether data came from cache.

## Local Development

```bash
npm run dev    # start local server at http://localhost:8787
gleam test     # run tests
```

## License

Unlicense (public domain). See [LICENSE](LICENSE) for details.
