# BC Hydro Proxy Worker

A Cloudflare Worker that proxies BC Hydro outage data and filters outages by geographic location.

## Features

- **Location-based filtering**: Query outages affecting specific coordinates (latitude/longitude)
- **Server-side caching**: Configurable cache TTL to reduce API calls
- **CORS enabled**: Works with web apps and Apple Shortcuts
- **Crew status details**: Human-readable descriptions of crew status codes
- **Fully tested**: 80+ unit tests covering all helper functions

## Project Structure

```
src/
  ├── index.js              # Main Worker entry point
  └── helpers/              # Coordinate validation, polygon geometry, status mappings

tests/                       # Unit tests for all helper modules
```

## Installation

```bash
npm install
```

## Local Development

### Running the Worker Locally

Start the local development server with Wrangler:

```bash
npm run dev
```

The worker will be available at `http://localhost:8787/?lat=X&lon=Y`

For more details on local development, testing, and debugging, see the [Wrangler documentation](https://developers.cloudflare.com/workers/testing/local-development/).

### Example Request

```bash
curl "http://localhost:8787/?lat=49.2827&lon=-123.1207" | jq .
```

### Example Response

```json
{
  "cached": false,
  "coordinates": {
    "latitude": 49.2827,
    "longitude": -123.1207
  },
  "totalOutages": 42,
  "affectingYou": 2,
  "outages": [
    {
      "id": "outage-123",
      "municipality": "Vancouver",
      "area": "Downtown",
      "cause": "Equipment failure",
      "numCustomersOut": 1500,
      "crewStatus": "ONSITE",
      "crewStatusDetail": "A crew is working to investigate...",
      "dateOff": "2025-01-15T14:30:00Z",
      "dateOn": "2025-01-15T16:00:00Z",
      "lastUpdated": "2025-01-15T14:45:00Z",
      "regionName": "Lower Mainland",
      "showEtr": true,
      "crewEtr": "2025-01-15T16:00:00Z",
      "latitude": 49.283,
      "longitude": -123.121
    }
  ]
}
```

## Testing

Run the test suite:

```bash
npm test                    # Run all tests
npm run test:watch         # Run tests in watch mode
```

## Configuration

Update `CACHE_MAX_AGE` in `wrangler.toml` to customize the server cache duration (default: 300 seconds).

## API

### Query Parameters

- `lat` (required): Latitude (-90 to 90)
- `lon` (required): Longitude (-180 to 180)

### Response Fields

- `cached` - Boolean indicating if response was served from cache
- `coordinates` - Echo of requested coordinates
- `totalOutages` - Total number of active outages in BC
- `affectingYou` - Number of outages affecting the specified coordinates
- `outages` - Array of affected outages with detailed information

### Error Responses

**Missing/Invalid Coordinates** (400):
```json
{
  "error": "Missing or invalid coordinates. Provide ?lat=XX.XXXX&lon=YY.YYYY query parameters",
  "outages": []
}
```

**Server Error** (500):
```json
{
  "error": "Error message details",
  "outages": []
}
```

## Data Source

The worker proxies data from BC Hydro's public API:
```
https://www.bchydro.com/power-outages/app/outages-map-data.json
```

## Caching Strategy

- **Server cache**: Configurable via `CACHE_MAX_AGE` (default: 300 seconds)
- **Client cache**: `Cache-Control: public, max-age=60` (capped at 1 minute)
- **Cache indicator**: `cached` field in response shows if data came from cache

First request: `cached: false`  
Subsequent requests (within TTL): `cached: true`

## Deployment

For deployment instructions, see the [Cloudflare Workers deployment documentation](https://developers.cloudflare.com/workers/deployment-trigger/).

## CI/CD

GitHub Actions runs automated checks on every push and pull request:

- **Linting**: Code quality checks with ESLint
- **Testing**: Tests run against Node.js 22.x and 24.x (LTS versions)
- **Gating**: All checks must pass before code can be deployed

Checks run on all pushes to `main` and pull requests into `main`. For more details, see the workflow configuration in `.github/workflows/ci.yaml`.

## License

Unlicense (public domain). See [LICENSE](LICENSE) file for details.