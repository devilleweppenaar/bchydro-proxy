import gleam/list

type Point {
  Point(lon: Float, lat: Float)
}

/// Returns True if the polygon is structurally valid:
/// a flat [lon, lat, ...] list with an even number of coordinates and at least 3 points.
/// In practice, polygon coordinates come from JSON decoding and are always finite.
pub fn is_valid_polygon(polygon: List(Float)) -> Bool {
  let len = list.length(polygon)
  len >= 6 && len % 2 == 0
}

/// Returns True if the point (lat, lon) lies inside the polygon using ray casting.
/// Polygon format: flat [lon1, lat1, lon2, lat2, ...] matching the BC Hydro API.
pub fn is_point_in_polygon(lat: Float, lon: Float, polygon: List(Float)) -> Bool {
  case is_valid_polygon(polygon) {
    False -> False
    True -> {
      let points = flat_to_points(polygon)
      case list.last(points) {
        Error(Nil) -> False
        Ok(last) -> ray_cast(lat, lon, points, last, False)
      }
    }
  }
}

fn flat_to_points(coords: List(Float)) -> List(Point) {
  case coords {
    [lon, lat, ..rest] -> [Point(lon: lon, lat: lat), ..flat_to_points(rest)]
    _ -> []
  }
}

fn ray_cast(
  lat: Float,
  lon: Float,
  points: List(Point),
  prev: Point,
  inside: Bool,
) -> Bool {
  case points {
    [] -> inside
    [curr, ..rest] -> {
      let new_inside = case check_intersection(lat, lon, curr, prev) {
        True -> !inside
        False -> inside
      }
      ray_cast(lat, lon, rest, curr, new_inside)
    }
  }
}

fn check_intersection(
  test_lat: Float,
  test_lon: Float,
  curr: Point,
  prev: Point,
) -> Bool {
  case { curr.lat >. test_lat } != { prev.lat >. test_lat } {
    False -> False
    True ->
      test_lon
      <. { prev.lon -. curr.lon }
      *. { test_lat -. curr.lat }
      /. { prev.lat -. curr.lat }
      +. curr.lon
  }
}
