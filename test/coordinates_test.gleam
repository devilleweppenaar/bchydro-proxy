import coordinates
import gleeunit/should

// --- is_valid_latitude ---

pub fn is_valid_latitude_accepts_typical_value_test() {
  coordinates.is_valid_latitude(49.2827)
  |> should.be_true()
}

pub fn is_valid_latitude_accepts_lower_bound_test() {
  coordinates.is_valid_latitude(-90.0)
  |> should.be_true()
}

pub fn is_valid_latitude_accepts_upper_bound_test() {
  coordinates.is_valid_latitude(90.0)
  |> should.be_true()
}

pub fn is_valid_latitude_rejects_above_range_test() {
  coordinates.is_valid_latitude(90.1)
  |> should.be_false()
}

pub fn is_valid_latitude_rejects_below_range_test() {
  coordinates.is_valid_latitude(-90.1)
  |> should.be_false()
}

// --- is_valid_longitude ---

pub fn is_valid_longitude_accepts_typical_value_test() {
  coordinates.is_valid_longitude(-123.1207)
  |> should.be_true()
}

pub fn is_valid_longitude_accepts_lower_bound_test() {
  coordinates.is_valid_longitude(-180.0)
  |> should.be_true()
}

pub fn is_valid_longitude_accepts_upper_bound_test() {
  coordinates.is_valid_longitude(180.0)
  |> should.be_true()
}

pub fn is_valid_longitude_rejects_above_range_test() {
  coordinates.is_valid_longitude(180.1)
  |> should.be_false()
}

pub fn is_valid_longitude_rejects_below_range_test() {
  coordinates.is_valid_longitude(-180.1)
  |> should.be_false()
}

// --- parse_coordinates ---

pub fn parse_coordinates_returns_parsed_floats_test() {
  coordinates.parse_coordinates("49.2827", "-123.1207")
  |> should.equal(Ok(#(49.2827, -123.1207)))
}

pub fn parse_coordinates_rejects_invalid_lat_test() {
  coordinates.parse_coordinates("not-a-number", "-123.1207")
  |> should.be_error()
}

pub fn parse_coordinates_rejects_invalid_lon_test() {
  coordinates.parse_coordinates("49.2827", "not-a-number")
  |> should.be_error()
}

pub fn parse_coordinates_rejects_empty_strings_test() {
  coordinates.parse_coordinates("", "")
  |> should.be_error()
}

pub fn parse_coordinates_rejects_out_of_range_lat_test() {
  coordinates.parse_coordinates("91.0", "-123.1207")
  |> should.be_error()
}

pub fn parse_coordinates_rejects_out_of_range_lon_test() {
  coordinates.parse_coordinates("49.2827", "181.0")
  |> should.be_error()
}

// --- is_in_bc_area ---

pub fn is_in_bc_area_accepts_vancouver_test() {
  coordinates.is_in_bc_area(49.2827, -123.1207)
  |> should.be_true()
}

pub fn is_in_bc_area_accepts_victoria_test() {
  coordinates.is_in_bc_area(48.4284, -123.3656)
  |> should.be_true()
}

pub fn is_in_bc_area_accepts_kelowna_test() {
  coordinates.is_in_bc_area(49.888, -119.496)
  |> should.be_true()
}

pub fn is_in_bc_area_rejects_coordinates_outside_bc_test() {
  coordinates.is_in_bc_area(43.6532, -79.3832)
  |> should.be_false()
}

pub fn is_in_bc_area_rejects_lat_below_bc_test() {
  coordinates.is_in_bc_area(48.2, -123.0)
  |> should.be_false()
}

pub fn is_in_bc_area_rejects_lat_above_bc_test() {
  coordinates.is_in_bc_area(60.1, -123.0)
  |> should.be_false()
}

pub fn is_in_bc_area_rejects_lon_west_of_bc_test() {
  coordinates.is_in_bc_area(54.0, -139.1)
  |> should.be_false()
}

pub fn is_in_bc_area_rejects_lon_east_of_bc_test() {
  coordinates.is_in_bc_area(54.0, -113.9)
  |> should.be_false()
}
