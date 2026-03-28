import polygon
import gleeunit/should

// A simple square polygon: [lon, lat, ...], covering the area
// lon -1.0 to 1.0, lat -1.0 to 1.0
const square = [-1.0, -1.0, 1.0, -1.0, 1.0, 1.0, -1.0, 1.0, -1.0, -1.0]

// A triangle: (0,2), (2,−2), (−2,−2) — lon, lat pairs
const triangle = [0.0, 2.0, 2.0, -2.0, -2.0, -2.0, 0.0, 2.0]

// The Vancouver downtown box from the BC Hydro test fixtures
const vancouver_box = [
  -123.15, 49.27, -123.1, 49.27, -123.1, 49.29, -123.15, 49.29, -123.15,
  49.27,
]

// --- is_valid_polygon ---

pub fn is_valid_polygon_accepts_triangle_test() {
  polygon.is_valid_polygon(triangle)
  |> should.be_true()
}

pub fn is_valid_polygon_accepts_square_test() {
  polygon.is_valid_polygon(square)
  |> should.be_true()
}

pub fn is_valid_polygon_rejects_empty_test() {
  polygon.is_valid_polygon([])
  |> should.be_false()
}

pub fn is_valid_polygon_rejects_too_few_points_test() {
  polygon.is_valid_polygon([0.0, 0.0, 1.0, 1.0])
  |> should.be_false()
}

pub fn is_valid_polygon_rejects_odd_coordinate_count_test() {
  polygon.is_valid_polygon([0.0, 0.0, 1.0, 1.0, 2.0])
  |> should.be_false()
}

// --- is_point_in_polygon ---

pub fn point_inside_square_test() {
  polygon.is_point_in_polygon(0.0, 0.0, square)
  |> should.be_true()
}

pub fn point_outside_square_test() {
  polygon.is_point_in_polygon(2.0, 2.0, square)
  |> should.be_false()
}

pub fn point_inside_triangle_test() {
  polygon.is_point_in_polygon(0.0, 0.0, triangle)
  |> should.be_true()
}

pub fn point_outside_triangle_test() {
  polygon.is_point_in_polygon(3.0, 3.0, triangle)
  |> should.be_false()
}

pub fn vancouver_point_inside_box_test() {
  polygon.is_point_in_polygon(49.2827, -123.1207, vancouver_box)
  |> should.be_true()
}

pub fn victoria_point_outside_vancouver_box_test() {
  polygon.is_point_in_polygon(48.4284, -123.3656, vancouver_box)
  |> should.be_false()
}

pub fn point_outside_invalid_polygon_test() {
  polygon.is_point_in_polygon(0.0, 0.0, [])
  |> should.be_false()
}
