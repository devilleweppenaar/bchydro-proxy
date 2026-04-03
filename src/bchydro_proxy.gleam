import coordinates
import gleam/dynamic
import gleam/dynamic/decode
import gleam/int
import gleam/javascript/promise.{type Promise}
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/uri
import outage
import polygon
import summary
import test_mode

// Opaque types for Cloudflare Workers platform objects.
pub type Request

pub type Response

pub type Env

// --- FFI ---

@external(javascript, "./cloudflare_ffi.mjs", "request_method")
fn ffi_request_method(req: Request) -> String

@external(javascript, "./cloudflare_ffi.mjs", "request_url")
fn ffi_request_url(req: Request) -> String

@external(javascript, "./cloudflare_ffi.mjs", "get_env_string")
fn ffi_get_env_string(env: Env, key: String) -> String

@external(javascript, "./cloudflare_ffi.mjs", "make_response")
fn ffi_make_response(
  body: String,
  status: Int,
  headers: List(#(String, String)),
) -> Response

@external(javascript, "./cloudflare_ffi.mjs", "fetch_outages_with_cache")
fn ffi_fetch_outages_with_cache(
  env: Env,
) -> Promise(Result(#(String, Bool, Int), String))

@external(javascript, "./cloudflare_ffi.mjs", "now_ms")
fn ffi_now_ms() -> Int

@external(javascript, "./cloudflare_ffi.mjs", "exception_message")
fn exception_message(err: dynamic.Dynamic) -> String

// --- Constants ---

const cors_headers: List(#(String, String)) = [
  #("Access-Control-Allow-Origin", "*"),
  #("Access-Control-Allow-Methods", "GET, OPTIONS"),
  #("Access-Control-Allow-Headers", "Content-Type"),
]

const test_prefix = "This is a test. "

// --- Entry point (exported to Cloudflare Worker via src/worker.js) ---

pub fn handle(request: Request, env: Env) -> Promise(Response) {
  case ffi_request_method(request) {
    "OPTIONS" -> promise.resolve(ffi_make_response("", 200, cors_headers))
    _ ->
      case get_path(ffi_request_url(request)) {
        "/guide" ->
          promise.resolve(
            make_redirect_response(ffi_get_env_string(env, "GUIDE_URL")),
          )
        _ ->
          handle_get(request, env)
          |> promise.rescue(fn(err) {
            make_error_response(500, exception_message(err))
          })
      }
  }
}

// --- Request handling ---

fn handle_get(request: Request, env: Env) -> Promise(Response) {
  let url_string = ffi_request_url(request)
  let params = parse_query_params(url_string)

  // Check test mode FIRST (before coordinate parsing and validation).
  let mode = case get_param(params, "test") {
    None -> test_mode.TestModeDisabled
    Some(test_param) ->
      test_mode.check_test_mode(
        ffi_get_env_string(env, "TEST_MODE") == "true",
        test_param,
      )
  }

  case mode {
    test_mode.TestModeDisabled -> handle_normal(params, env)

    test_mode.TestModeInvalidParam ->
      promise.resolve(make_error_response(
        400,
        "Invalid test mode. Valid options: outage, no-outage, multiple, error",
      ))

    test_mode.TestModeError ->
      promise.resolve(make_error_response(
        500,
        test_prefix <> "The BC Hydro outage service returned an error.",
      ))

    test_mode.TestModeActive(scenario) -> {
      let now = ffi_now_ms()
      let outages = test_mode.test_outages(scenario, now)
      let body =
        build_response_body(
          False,
          49.2827,
          -123.1207,
          outages,
          now,
          test_prefix,
        )
      promise.resolve(
        make_json_response(body, 200, [
          #("Cache-Control", "no-cache"),
        ]),
      )
    }
  }
}

fn handle_normal(params: List(#(String, String)), env: Env) -> Promise(Response) {
  let lat_str = get_param(params, "lat") |> option.unwrap("")
  let lon_str = get_param(params, "lon") |> option.unwrap("")

  case coordinates.parse_coordinates(lat_str, lon_str) {
    Error(Nil) ->
      promise.resolve(make_error_response(
        400,
        "Your coordinates are missing or invalid. Latitude and longitude are required.",
      ))

    Ok(#(lat, lon)) ->
      case coordinates.is_in_bc_area(lat, lon) {
        False ->
          promise.resolve(make_error_response(
            400,
            "Your coordinates are outside the BC Hydro service area.",
          ))

        True -> fetch_and_respond(lat, lon, env)
      }
  }
}

fn fetch_and_respond(lat: Float, lon: Float, env: Env) -> Promise(Response) {
  ffi_fetch_outages_with_cache(env)
  |> promise.try_await(fn(cache_data) {
    let #(json_str, cache_hit, cache_max_age) = cache_data
    case json.parse(json_str, decode.list(outage.decoder())) {
      Error(_) ->
        promise.resolve(Error("The BC Hydro outage data could not be read."))
      Ok(all_outages) -> {
        let now = ffi_now_ms()
        let body =
          build_response_body(cache_hit, lat, lon, all_outages, now, "")
        let client_max_age = int.min(60, cache_max_age)
        promise.resolve(
          Ok(
            make_json_response(body, 200, [
              #(
                "Cache-Control",
                "public, max-age=" <> int.to_string(client_max_age),
              ),
            ]),
          ),
        )
      }
    }
  })
  |> promise.map(fn(result) {
    case result {
      Ok(response) -> response
      Error(msg) -> make_error_response(500, msg)
    }
  })
}

// --- Response building ---

fn build_response_body(
  cache_hit: Bool,
  lat: Float,
  lon: Float,
  all_outages: List(outage.Outage),
  now_ms: Int,
  summary_prefix: String,
) -> String {
  let affected =
    list.filter(all_outages, fn(o) {
      case o.polygon {
        [] -> False
        _ -> polygon.is_point_in_polygon(lat, lon, o.polygon)
      }
    })

  json.to_string(
    json.object([
      #(
        "summary",
        json.string(summary.build_summary(affected, now_ms, summary_prefix)),
      ),
      #("cached", json.bool(cache_hit)),
      #(
        "coordinates",
        json.object([
          #("latitude", json.float(lat)),
          #("longitude", json.float(lon)),
        ]),
      ),
      #("totalOutages", json.int(list.length(all_outages))),
      #("affectingYou", json.int(list.length(affected))),
      #("outages", json.array(affected, outage.encode_for_response)),
    ]),
  )
}

fn make_json_response(
  body: String,
  status: Int,
  extra_headers: List(#(String, String)),
) -> Response {
  let headers =
    cors_headers
    |> list.append([#("Content-Type", "application/json")])
    |> list.append(extra_headers)
  ffi_make_response(body, status, headers)
}

fn make_redirect_response(url: String) -> Response {
  ffi_make_response("", 302, cors_headers |> list.append([#("Location", url)]))
}

fn make_error_response(status: Int, message: String) -> Response {
  let body =
    json.to_string(
      json.object([
        #("error", json.string(message)),
        #("outages", json.preprocessed_array([])),
      ]),
    )
  make_json_response(body, status, [])
}

// --- URL parsing helpers ---

pub fn get_path(url_string: String) -> String {
  case uri.parse(url_string) {
    Error(_) -> "/"
    Ok(parsed) -> parsed.path
  }
}

fn parse_query_params(url_string: String) -> List(#(String, String)) {
  case uri.parse(url_string) {
    Error(_) -> []
    Ok(parsed) ->
      case parsed.query {
        None -> []
        Some(q) ->
          case uri.parse_query(q) {
            Error(_) -> []
            Ok(params) -> params
          }
      }
  }
}

fn get_param(params: List(#(String, String)), key: String) -> Option(String) {
  list.find(params, fn(pair) { pair.0 == key })
  |> option.from_result
  |> option.map(fn(pair) { pair.1 })
}
