// Cloudflare Workers FFI — JavaScript bindings for Gleam
// Handles platform-specific APIs: Request/Response, Env, Cache, fetch

// Gleam's Result classes must be used so pattern matching (instanceof Ok/Error) works.
import { Ok, Error as GleamError } from "../gleam_stdlib/gleam.mjs";

const BCHYDRO_API_URL =
  "https://www.bchydro.com/power-outages/app/outages-map-data.json";
const CACHE_KEY = "https://cache.bchydro-proxy.internal/outages";

export function request_method(request) {
  return request.method;
}

export function request_url(request) {
  return request.url;
}

// Returns the env binding as a string, or "" if missing.
export function get_env_string(env, key) {
  return String(env[key] ?? "");
}

// Builds a Response from a Gleam List(#(String, String)) of headers.
// Gleam lists are iterable and tuples are plain JS arrays.
export function make_response(body, status, headers) {
  const h = new Headers();
  for (const [key, value] of headers) {
    h.set(key, value);
  }
  return new Response(body || null, { status, headers: h });
}

// Fetches BC Hydro outages, using Cloudflare's Cache API as a server-side cache.
// Returns: Promise(Result(#(json_string, was_cached, max_age_seconds), error_message))
// Gleam tuple #(a, b, c): plain JS array [a, b, c]
export async function fetch_outages_with_cache(env) {
  const maxAge = parseInt(env.CACHE_MAX_AGE || "300");
  const cache = caches.default;

  const cached = await cache.match(new Request(CACHE_KEY));
  if (cached) {
    console.log("Cache hit - using cached data");
    const data = await cached.text();
    return new Ok([data, true, maxAge]);
  }

  console.log("Fetching from BC Hydro API");
  const response = await fetch(BCHYDRO_API_URL, {
    headers: { "User-Agent": "BCHydroProxy/1.0" },
  });

  if (!response.ok) {
    return new GleamError(`BC Hydro API returned ${response.status}`);
  }

  const data = await response.text();

  await cache.put(
    new Request(CACHE_KEY),
    new Response(data, {
      headers: {
        "Content-Type": "application/json",
        "Cache-Control": `public, max-age=${maxAge}`,
      },
    }),
  );

  return new Ok([data, false, maxAge]);
}

export function now_ms() {
  return Date.now();
}

// Extracts a message string from a caught JavaScript exception.
export function exception_message(err) {
  if (err instanceof Error) return err.message;
  if (typeof err === "string") return err;
  return String(err);
}
