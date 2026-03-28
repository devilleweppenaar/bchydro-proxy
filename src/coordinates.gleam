import gleam/float
import gleam/result

pub fn is_valid_latitude(lat: Float) -> Bool {
  lat >=. -90.0 && lat <=. 90.0
}

pub fn is_valid_longitude(lon: Float) -> Bool {
  lon >=. -180.0 && lon <=. 180.0
}

/// Parse and validate lat/lon strings. Returns Ok(#(lat, lon)) or Error(Nil).
pub fn parse_coordinates(
  lat_str: String,
  lon_str: String,
) -> Result(#(Float, Float), Nil) {
  use lat <- result.try(float.parse(lat_str))
  use lon <- result.try(float.parse(lon_str))
  case is_valid_latitude(lat) && is_valid_longitude(lon) {
    True -> Ok(#(lat, lon))
    False -> Error(Nil)
  }
}

/// Returns True if the coordinates fall within BC Hydro's service area.
/// Latitude: 48.3–60.0°N, Longitude: -139.0 to -114.0°W
pub fn is_in_bc_area(lat: Float, lon: Float) -> Bool {
  lat >=. 48.3 && lat <=. 60.0 && lon >=. -139.0 && lon <=. -114.0
}
