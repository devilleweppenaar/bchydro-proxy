import { parseCoordinates, isInBCArea } from "./helpers/coordinates.js";
import { isPointInPolygon } from "./helpers/polygon.js";
import { getCrewStatusDetail } from "./helpers/crew.js";
import { getTestMode, getTestOutages } from "./helpers/test-mode.js";

/**
 * CORS headers for cross-origin requests
 */
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type",
};

/**
 * Build the response object with filtered outages
 */
function buildResponse(cacheHit, userLat, userLon, allOutages, _cacheMaxAge) {
  // Filter outages that affect the user's coordinates
  const affectedOutages = allOutages.filter((outage) => {
    // Check if the outage has a polygon
    if (!outage.polygon || outage.polygon.length === 0) {
      return false;
    }

    // Check if user's coordinates are inside the outage polygon
    return isPointInPolygon(userLat, userLon, outage.polygon);
  });

  // Prepare response data
  return {
    cached: cacheHit,
    coordinates: {
      latitude: userLat,
      longitude: userLon,
    },
    totalOutages: allOutages.length,
    affectingYou: affectedOutages.length,
    outages: affectedOutages.map((outage) => ({
      id: outage.id,
      municipality: outage.municipality,
      area: outage.area,
      cause: outage.cause,
      numCustomersOut: outage.numCustomersOut,
      crewStatus: outage.crewStatus,
      crewStatusDescription: outage.crewStatusDescription,
      crewStatusDetail: getCrewStatusDetail(outage.crewStatus),
      dateOff: outage.dateOff,
      dateOn: outage.dateOn,
      lastUpdated: outage.lastUpdated,
      regionName: outage.regionName,
      showEtr: outage.showEtr,
      crewEtr: outage.crewEtr,
      latitude: outage.latitude,
      longitude: outage.longitude,
    })),
  };
}

/**
 * Fetch outages from BC Hydro API and cache them
 */
async function getOutagesWithCache(env) {
  const cacheMaxAge = parseInt(env.CACHE_MAX_AGE || "300");
  const cacheKey = new Request("https://cache.bchydro-proxy.internal/outages", {
    method: "GET",
  });
  const cache = typeof caches !== "undefined" ? caches.default : null;

  // Try to get from cache
  if (cache) {
    const cachedResponse = await cache.match(cacheKey);
    if (cachedResponse) {
      // eslint-disable-next-line no-console
      console.log("Cache hit - using cached data");
      const data = await cachedResponse.text();
      return {
        allOutages: JSON.parse(data),
        cacheHit: true,
        cacheMaxAge,
      };
    }
  }

  // Cache miss - fetch from BC Hydro
  // eslint-disable-next-line no-console
  console.log("Fetching from BC Hydro API");
  const bcHydroResponse = await fetch(
    "https://www.bchydro.com/power-outages/app/outages-map-data.json",
    {
      headers: {
        "User-Agent": "BCHydroProxy/1.0",
      },
    },
  );

  if (!bcHydroResponse.ok) {
    throw new Error(`BC Hydro API returned ${bcHydroResponse.status}`);
  }

  const data = await bcHydroResponse.text();
  const allOutages = JSON.parse(data);

  // Cache the raw data if caching is available
  if (cache) {
    const cacheResponse = new Response(data, {
      headers: {
        "Content-Type": "application/json",
        "Cache-Control": `public, max-age=${cacheMaxAge}`,
      },
    });
    await cache.put(cacheKey, cacheResponse.clone());
  }

  return {
    allOutages,
    cacheHit: false,
    cacheMaxAge,
  };
}

export default {
  async fetch(request, env) {
    // Handle OPTIONS request for CORS
    if (request.method === "OPTIONS") {
      return new Response(null, { headers: corsHeaders });
    }

    try {
      const url = new URL(request.url);

      // Check test mode FIRST (before any validation)
      const testParam = url.searchParams.get("test");
      if (testParam) {
        const testModeStatus = getTestMode(env, testParam);

        // If test mode is enabled but param is invalid, return error
        if (testModeStatus.enabled && !testModeStatus.valid) {
          return new Response(
            JSON.stringify({
              error: "Invalid test mode. Valid options: outage, no-outage, multiple",
              outages: [],
            }),
            {
              status: 400,
              headers: {
                ...corsHeaders,
                "Content-Type": "application/json",
              },
            },
          );
        }

        // If test mode is valid, use test data (skip all validation)
        if (testModeStatus.mode) {
          // eslint-disable-next-line no-console
          console.log(`Test mode enabled: ${testModeStatus.mode}`);
          const allOutages = getTestOutages(testModeStatus.mode);

          // Use generic Vancouver coordinates for test mode
          const testCoords = { lat: 49.2827, lon: -123.1207 };

          const responseData = buildResponse(
            false, // Test data is never cached
            testCoords.lat,
            testCoords.lon,
            allOutages,
            parseInt(env.CACHE_MAX_AGE || "300"),
          );

          return new Response(JSON.stringify(responseData, null, 2), {
            headers: {
              ...corsHeaders,
              "Content-Type": "application/json",
              "Cache-Control": "no-cache", // Don't cache test responses
            },
          });
        }
      }

      // Normal mode: validate coordinates
      const coords = parseCoordinates(
        url.searchParams.get("lat"),
        url.searchParams.get("lon"),
      );

      if (!coords) {
        return new Response(
          JSON.stringify({
            error:
              "Missing or invalid coordinates. Provide ?lat=XX.XXXX&lon=YY.YYYY query parameters",
            outages: [],
          }),
          {
            status: 400,
            headers: {
              ...corsHeaders,
              "Content-Type": "application/json",
            },
          },
        );
      }

      const { lat: userLat, lon: userLon } = coords;

      // Validate coordinates are within BC Hydro service area
      if (!isInBCArea(userLat, userLon)) {
        return new Response(
          JSON.stringify({
            error:
              "Coordinates outside BC Hydro service area (British Columbia, Canada)",
            outages: [],
          }),
          {
            status: 400,
            headers: {
              ...corsHeaders,
              "Content-Type": "application/json",
            },
          },
        );
      }

      // Get outages with caching
      const { allOutages, cacheHit, cacheMaxAge } =
        await getOutagesWithCache(env);

      // Build response
      const responseData = buildResponse(
        cacheHit,
        userLat,
        userLon,
        allOutages,
        cacheMaxAge,
      );

      // Return filtered results
      return new Response(JSON.stringify(responseData, null, 2), {
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json",
          "Cache-Control": `public, max-age=${Math.min(60, cacheMaxAge)}`, // Client cache (max 1 minute)
        },
      });
    } catch (error) {
      // eslint-disable-next-line no-console
      console.error("Worker error:", error);
      return new Response(
        JSON.stringify({
          error: error.message,
          outages: [],
        }),
        {
          status: 500,
          headers: {
            ...corsHeaders,
            "Content-Type": "application/json",
          },
        },
      );
    }
  },
};
