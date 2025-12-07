/**
 * Validate latitude value
 * @param {number} lat - Latitude to validate
 * @returns {boolean} - True if valid latitude
 */
export function isValidLatitude(lat) {
  return typeof lat === "number" && isFinite(lat) && lat >= -90 && lat <= 90;
}

/**
 * Validate longitude value
 * @param {number} lon - Longitude to validate
 * @returns {boolean} - True if valid longitude
 */
export function isValidLongitude(lon) {
  return typeof lon === "number" && isFinite(lon) && lon >= -180 && lon <= 180;
}

/**
 * Parse and validate coordinates from string parameters
 * @param {string} latStr - Latitude string to parse
 * @param {string} lonStr - Longitude string to parse
 * @returns {{lat: number, lon: number} | null} - Parsed coordinates or null if invalid
 */
export function parseCoordinates(latStr, lonStr) {
  const lat = parseFloat(latStr || "");
  const lon = parseFloat(lonStr || "");

  if (!isValidLatitude(lat) || !isValidLongitude(lon)) {
    return null;
  }

  return { lat, lon };
}

/**
 * Check if coordinates are within reasonable bounds for BC Hydro service area
 * @param {number} lat - Latitude
 * @param {number} lon - Longitude
 * @returns {boolean} - True if coordinates are in BC area
 */
export function isInBCArea(lat, lon) {
  // Validate input types first
  if (!isValidLatitude(lat) || !isValidLongitude(lon)) {
    return false;
  }

  // Approximate bounds for British Columbia
  const minLat = 48.3;
  const maxLat = 60.0;
  const minLon = -139.0;
  const maxLon = -114.0;

  return lat >= minLat && lat <= maxLat && lon >= minLon && lon <= maxLon;
}
