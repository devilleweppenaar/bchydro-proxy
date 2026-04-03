import bchydro_proxy
import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

// --- get_path ---

pub fn get_path_returns_guide_path_test() {
  bchydro_proxy.get_path("https://example.com/guide")
  |> should.equal("/guide")
}

pub fn get_path_returns_root_for_root_url_test() {
  bchydro_proxy.get_path("https://example.com/")
  |> should.equal("/")
}

pub fn get_path_returns_root_for_query_only_url_test() {
  bchydro_proxy.get_path("https://example.com/?lat=49.2827&lon=-123.1207")
  |> should.equal("/")
}
