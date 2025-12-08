/**
 * Test data fixtures for test mode
 * Used when TEST_MODE environment variable is enabled
 */

/**
 * Generate a polygon that covers downtown Vancouver (49.2827, -123.1207)
 * This creates a box around downtown Vancouver for testing outage scenarios
 */
function getVancouverDowntownPolygon() {
  // Box covering downtown Vancouver area
  // Format: [lon, lat, lon, lat, ...] (BC Hydro polygon format)
  return [
    -123.15, 49.27, // Southwest corner
    -123.1, 49.27, // Southeast corner
    -123.1, 49.29, // Northeast corner
    -123.15, 49.29, // Northwest corner
    -123.15, 49.27, // Close the polygon
  ];
}

/**
 * Generate a polygon for Victoria area (doesn't cover Vancouver)
 * Used for testing "no outage" scenario
 */
function getVictoriaPolygon() {
  // Box covering Victoria area (48.4284, -123.3656)
  return [
    -123.4, 48.4, // Southwest corner
    -123.3, 48.4, // Southeast corner
    -123.3, 48.45, // Northeast corner
    -123.4, 48.45, // Northwest corner
    -123.4, 48.4, // Close the polygon
  ];
}

/**
 * Generate a polygon for Kelowna area (doesn't cover Vancouver)
 * Used for testing multiple outages
 */
function getKelownaPolygon() {
  // Box covering Kelowna area (49.8880, -119.4960)
  return [
    -119.55, 49.85, // Southwest corner
    -119.45, 49.85, // Southeast corner
    -119.45, 49.93, // Northeast corner
    -119.55, 49.93, // Northwest corner
    -119.55, 49.85, // Close the polygon
  ];
}

/**
 * Generate mock outage data for testing
 * @param {string} testMode - The test mode type (outage, no-outage, multiple)
 * @returns {Array} Array of mock outage objects
 */
export function getTestOutages(testMode) {
  const now = Date.now();
  const oneHourAgo = now - 3600000;
  const twoHoursFromNow = now + 7200000;

  switch (testMode) {
  case "outage":
    // Single outage affecting downtown Vancouver
    return [
      {
        id: "test-outage-001",
        municipality: "Vancouver",
        area: "Downtown",
        cause: "Equipment failure (TEST DATA)",
        numCustomersOut: 1500,
        crewStatus: "ONSITE",
        crewStatusDescription: "Crew on-site",
        dateOff: oneHourAgo,
        dateOn: twoHoursFromNow,
        lastUpdated: now,
        regionName: "Lower Mainland",
        showEtr: true,
        crewEtr: twoHoursFromNow,
        latitude: 49.2827,
        longitude: -123.1207,
        polygon: getVancouverDowntownPolygon(),
      },
    ];

  case "no-outage":
    // Outage in Victoria (doesn't affect Vancouver coordinates)
    return [
      {
        id: "test-outage-002",
        municipality: "Victoria",
        area: "James Bay",
        cause: "Tree down across our wires (TEST DATA)",
        numCustomersOut: 245,
        crewStatus: "ENROUTE",
        crewStatusDescription: "Crew en route",
        dateOff: oneHourAgo,
        dateOn: twoHoursFromNow,
        lastUpdated: now,
        regionName: "Vancouver Island",
        showEtr: true,
        crewEtr: twoHoursFromNow,
        latitude: 48.4284,
        longitude: -123.3656,
        polygon: getVictoriaPolygon(),
      },
    ];

  case "multiple":
    // Multiple outages - one affecting Vancouver, others not
    return [
      {
        id: "test-outage-003",
        municipality: "Vancouver",
        area: "Downtown Core",
        cause: "Underground cable fault (TEST DATA)",
        numCustomersOut: 850,
        crewStatus: "ONSITE",
        crewStatusDescription: "Crew on-site",
        dateOff: oneHourAgo,
        dateOn: twoHoursFromNow,
        lastUpdated: now,
        regionName: "Lower Mainland",
        showEtr: true,
        crewEtr: twoHoursFromNow,
        latitude: 49.2827,
        longitude: -123.1207,
        polygon: getVancouverDowntownPolygon(),
      },
      {
        id: "test-outage-004",
        municipality: "Vancouver",
        area: "West End",
        cause: "Motor vehicle accident (TEST DATA)",
        numCustomersOut: 420,
        crewStatus: "ASSIGNED",
        crewStatusDescription: "Crew assigned",
        dateOff: oneHourAgo - 1800000,
        dateOn: twoHoursFromNow + 1800000,
        lastUpdated: now - 900000,
        regionName: "Lower Mainland",
        showEtr: true,
        crewEtr: twoHoursFromNow + 1800000,
        latitude: 49.285,
        longitude: -123.13,
        polygon: [
          -123.16, 49.275, -123.12, 49.275, -123.12, 49.295, -123.16,
          49.295, -123.16, 49.275,
        ],
      },
      {
        id: "test-outage-005",
        municipality: "Kelowna",
        area: "Rutland",
        cause: "Planned maintenance (TEST DATA)",
        numCustomersOut: 125,
        crewStatus: "NOT_ASSIGNED",
        crewStatusDescription: "Not assigned",
        dateOff: oneHourAgo,
        dateOn: twoHoursFromNow,
        lastUpdated: now,
        regionName: "Interior",
        showEtr: false,
        crewEtr: null,
        latitude: 49.888,
        longitude: -119.496,
        polygon: getKelownaPolygon(),
      },
    ];

  default:
    return [];
  }
}

/**
 * Check if test mode is enabled and valid
 * @param {object} env - Environment variables
 * @param {string} testParam - Test query parameter value
 * @returns {string|null} Test mode type if valid, null otherwise
 */
export function getTestMode(env, testParam) {
  // Test mode must be explicitly enabled via environment variable
  if (env.TEST_MODE !== "true") {
    return null;
  }

  // Validate test parameter
  const validTestModes = ["outage", "no-outage", "multiple"];
  if (validTestModes.includes(testParam)) {
    return testParam;
  }

  return null;
}
