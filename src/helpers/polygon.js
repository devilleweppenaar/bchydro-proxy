/**
 * Point-in-polygon algorithm using ray casting
 * @param {number} lat - Latitude of the point to test
 * @param {number} lon - Longitude of the point to test
 * @param {number[]} polygon - Flat array of coordinates [lon1, lat1, lon2, lat2, ...]
 * @returns {boolean} - True if point is inside polygon
 */
export function isPointInPolygon(lat, lon, polygon) {
  // Validate inputs
  if (typeof lat !== "number" || !isFinite(lat)) {
    return false;
  }
  if (typeof lon !== "number" || !isFinite(lon)) {
    return false;
  }
  if (!isValidPolygon(polygon)) {
    return false;
  }

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

/**
 * Validate a polygon array
 * @param {any} polygon - Value to validate as a polygon
 * @returns {boolean} - True if polygon is valid
 */
export function isValidPolygon(polygon) {
  // Must be an array
  if (!Array.isArray(polygon)) {
    return false;
  }

  // Must have even number of coordinates (lon, lat pairs)
  if (polygon.length % 2 !== 0) {
    return false;
  }

  // Must have at least 3 points (6 coordinates)
  if (polygon.length < 6) {
    return false;
  }

  // All coordinates must be valid numbers
  for (let i = 0; i < polygon.length; i++) {
    const coord = polygon[i];
    if (typeof coord !== "number" || !isFinite(coord)) {
      return false;
    }
  }

  return true;
}
