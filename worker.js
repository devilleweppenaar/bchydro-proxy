/**
 * Map crew status codes to detailed human-readable descriptions
 */
function getCrewStatusDetail(crewStatus) {
  const statusMap = {
    NOT_ASSIGNED:
      "A crew hasn't been assigned to the outage yet. We're working around the clock to get power restored but we don't have updates at this point. If the status was previously assigned but changed back to not-assigned, the crew may have been called away to address an immediate safety issue or emergency, other work took longer than anticipated, or additional damage was found and we had to shift resources.",
    ASSIGNED:
      "A crew has been assigned to the area and your outage is on their list to tackle when they can.",
    ENROUTE: "A crew is on their way to investigate your outage.",
    ONSITE:
      "A crew is working to investigate the cause of the outage and determine the required repairs and we'll have an estimated time of restoration (ETR) soon.",
    SUSPENDED:
      "The initial crew that arrived and assessed the problem needed different equipment. This usually means heavy equipment or materials like new poles, or additional personnel to tackle the problem and it's not currently assigned to a specific crew.",
  };

  return statusMap[crewStatus] || null;
}

export default {
  async fetch(request, env) {
    // Add CORS headers for Shortcuts
    const corsHeaders = {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "GET, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type",
    };

    // Handle OPTIONS request for CORS
    if (request.method === "OPTIONS") {
      return new Response(null, { headers: corsHeaders });
    }

    try {
      // Get coordinates from query parameters
      const url = new URL(request.url);
      const userLat = parseFloat(url.searchParams.get("lat") || "");
      const userLon = parseFloat(url.searchParams.get("lon") || "");

      // Get cache duration (default 5 minutes = 300 seconds)
      const cacheMaxAge = parseInt(env.CACHE_MAX_AGE || "300");

      if (isNaN(userLat) || isNaN(userLon)) {
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

      // Try to get cached response (only available in Cloudflare Workers environment)
      let allOutages;
      let response = null;
      let cacheHit = false;

      if (typeof caches !== "undefined") {
        const cacheKey = new Request(
          "https://cache.bchydro-proxy.internal/outages",
          { method: "GET" },
        );
        const cache = caches.default;
        response = await cache.match(cacheKey);
      }

      if (!response) {
        // Cache miss or caching not available - fetch from BC Hydro
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
        allOutages = JSON.parse(data);

        // Cache the raw data (duration configurable via CACHE_MAX_AGE env var)
        if (typeof caches !== "undefined") {
          const cacheKey = new Request(
            "https://cache.bchydro-proxy.internal/outages",
            { method: "GET" },
          );
          const cache = caches.default;
          const cacheResponse = new Response(data, {
            headers: {
              "Content-Type": "application/json",
              "Cache-Control": `public, max-age=${cacheMaxAge}`,
            },
          });
          await cache.put(cacheKey, cacheResponse.clone());
        }
      } else {
        // Cache hit
        console.log("Cache hit - using cached data");
        cacheHit = true;
        const data = await response.text();
        allOutages = JSON.parse(data);
      }

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
      const responseData = {
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

      // Return filtered results
      return new Response(JSON.stringify(responseData, null, 2), {
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json",
          "Cache-Control": `public, max-age=${Math.min(60, cacheMaxAge)}`, // Client cache (max 1 minute)
        },
      });
    } catch (error) {
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

/**
 * Point-in-polygon algorithm using ray casting
 * @param {number} lat - Latitude of the point to test
 * @param {number} lon - Longitude of the point to test
 * @param {number[]} polygon - Flat array of coordinates [lon1, lat1, lon2, lat2, ...]
 * @returns {boolean} - True if point is inside polygon
 */
function isPointInPolygon(lat, lon, polygon) {
  // Convert flat array to array of points
  const points = [];
  for (let i = 0; i < polygon.length; i += 2) {
    points.push({
      lon: polygon[i],
      lat: polygon[i + 1],
    });
  }

  let inside = false;

  for (let i = 0, j = points.length - 1; i < points.length; j = i++) {
    const xi = points[i].lon;
    const yi = points[i].lat;
    const xj = points[j].lon;
    const yj = points[j].lat;

    // Ray casting algorithm
    const intersect =
      yi > lat !== yj > lat && lon < ((xj - xi) * (lat - yi)) / (yj - yi) + xi;

    if (intersect) {
      inside = !inside;
    }
  }

  return inside;
}
