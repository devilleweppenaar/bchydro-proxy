import crew
import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/option.{type Option}

pub type Outage {
  Outage(
    id: String,
    municipality: String,
    area: String,
    cause: String,
    num_customers_out: Int,
    crew_status: String,
    crew_status_description: String,
    date_off: Int,
    date_on: Option(Int),
    last_updated: Int,
    region_name: String,
    show_etr: Bool,
    crew_etr: Option(Int),
    latitude: Float,
    longitude: Float,
    polygon: List(Float),
  )
}

/// Decoder for a single outage from the BC Hydro API JSON response.
pub fn decoder() -> decode.Decoder(Outage) {
  use id_int <- decode.field("id", decode.int)
  let id = int.to_string(id_int)
  use municipality <- decode.field("municipality", decode.string)
  use area <- decode.field("area", decode.string)
  use cause <- decode.field("cause", decode.string)
  use num_customers_out <- decode.field("numCustomersOut", decode.int)
  use crew_status <- decode.field("crewStatus", decode.string)
  use crew_status_description <- decode.field(
    "crewStatusDescription",
    decode.string,
  )
  use date_off <- decode.field("dateOff", decode.int)
  use date_on <- decode.field("dateOn", decode.optional(decode.int))
  use last_updated <- decode.field("lastUpdated", decode.int)
  use region_name <- decode.field("regionName", decode.string)
  use show_etr <- decode.field("showEtr", decode.bool)
  use crew_etr <- decode.field("crewEtr", decode.optional(decode.int))
  use latitude <- decode.field("latitude", decode.float)
  use longitude <- decode.field("longitude", decode.float)
  use polygon <- decode.field("polygon", decode.list(decode.float))
  decode.success(Outage(
    id:,
    municipality:,
    area:,
    cause:,
    num_customers_out:,
    crew_status:,
    crew_status_description:,
    date_off:,
    date_on:,
    last_updated:,
    region_name:,
    show_etr:,
    crew_etr:,
    latitude:,
    longitude:,
    polygon:,
  ))
}

/// Encodes an outage for the API response. Does not include the polygon.
/// Enriches the outage with a human-readable crew status detail.
pub fn encode_for_response(o: Outage) -> json.Json {
  let detail =
    crew.parse_crew_status(o.crew_status)
    |> option.map(crew.crew_status_detail)

  json.object([
    #("id", json.string(o.id)),
    #("municipality", json.string(o.municipality)),
    #("area", json.string(o.area)),
    #("cause", json.string(o.cause)),
    #("numCustomersOut", json.int(o.num_customers_out)),
    #("crewStatus", json.string(o.crew_status)),
    #("crewStatusDescription", json.string(o.crew_status_description)),
    #("crewStatusDetail", json.nullable(detail, json.string)),
    #("dateOff", json.int(o.date_off)),
    #("dateOn", json.nullable(o.date_on, json.int)),
    #("lastUpdated", json.int(o.last_updated)),
    #("regionName", json.string(o.region_name)),
    #("showEtr", json.bool(o.show_etr)),
    #("crewEtr", json.nullable(o.crew_etr, json.int)),
    #("latitude", json.float(o.latitude)),
    #("longitude", json.float(o.longitude)),
  ])
}
