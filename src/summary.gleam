import crew
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import outage.{type Outage}

type CauseResult {
  MappedCause(String)
  UnknownCause(String)
  SkipCause
}

/// Builds a natural language summary for the given list of outages affecting
/// the queried location. Intended for direct display or voice readout.
/// `prefix` is prepended to the result (use `""` for normal mode,
/// `"This is a test. "` for test mode responses).
pub fn build_summary(
  outages: List(Outage),
  now_ms: Int,
  prefix: String,
) -> String {
  let base = case outages {
    [] -> "There are no outages in your area."
    [single] ->
      assemble(
        "There is an outage in your area.",
        "Power has been out",
        single,
        now_ms,
      )
    multiple -> {
      let count = list.length(multiple)
      let sorted =
        list.sort(multiple, by: fn(a, b) {
          int.compare(b.num_customers_out, a.num_customers_out)
        })
      case list.first(sorted) {
        Error(_) ->
          "There are " <> int.to_string(count) <> " outages in your area."
        Ok(primary) ->
          assemble(
            "There are " <> int.to_string(count) <> " outages in your area.",
            "The most significant has been out",
            primary,
            now_ms,
          )
      }
    }
  }
  prefix <> base
}

fn assemble(
  intro: String,
  power_subject: String,
  o: Outage,
  now_ms: Int,
) -> String {
  let elapsed = now_ms - o.date_off
  let cause_result = resolve_cause(o.cause)

  let power_sentence = case cause_result {
    MappedCause(phrase) ->
      power_subject
      <> " for "
      <> duration_phrase(elapsed)
      <> " due to "
      <> phrase
      <> "."
    UnknownCause(_) | SkipCause ->
      power_subject <> " for " <> duration_phrase(elapsed) <> "."
  }

  let cause_sentence = case cause_result {
    UnknownCause(raw) -> "The cause is listed as: " <> raw <> "."
    _ -> ""
  }

  [
    intro,
    power_sentence,
    cause_sentence,
    crew_sentence(o.crew_status),
    etr_sentence(o.show_etr, o.crew_etr, now_ms),
  ]
  |> list.filter(fn(s) { s != "" })
  |> string.join(" ")
}

fn duration_phrase(ms: Int) -> String {
  let dur = format_duration(ms)
  case dur {
    "less than a minute" -> dur
    _ -> "about " <> dur
  }
}

fn format_duration(ms: Int) -> String {
  let total_minutes = ms / 60_000
  let hours = total_minutes / 60
  let days = hours / 24
  let rem_minutes = total_minutes - hours * 60

  case days > 0, hours > 0, total_minutes > 0 {
    True, _, _ -> int.to_string(days) <> " " <> pluralize(days, "day")
    _, True, _ ->
      case rem_minutes {
        0 -> int.to_string(hours) <> " " <> pluralize(hours, "hour")
        _ ->
          int.to_string(hours)
          <> " "
          <> pluralize(hours, "hour")
          <> " and "
          <> int.to_string(rem_minutes)
          <> " "
          <> pluralize(rem_minutes, "minute")
      }
    _, _, True ->
      int.to_string(total_minutes) <> " " <> pluralize(total_minutes, "minute")
    _, _, _ -> "less than a minute"
  }
}

fn pluralize(n: Int, word: String) -> String {
  case n {
    1 -> word
    _ -> word <> "s"
  }
}

fn resolve_cause(cause: String) -> CauseResult {
  case string.lowercase(cause) {
    "bird contacting our wires" -> MappedCause("a bird contacting the lines")
    "cable fault" -> MappedCause("a cable fault")
    "customer's equipment" -> MappedCause("a customer's equipment issue")
    "equipment failure" -> MappedCause("equipment failure")
    "equipment contact" -> MappedCause("equipment contact")
    "fire" -> MappedCause("a fire")
    "motor vehicle accident" -> MappedCause("a motor vehicle accident")
    "mud or snow slide" -> MappedCause("a mud or snow slide")
    "object on our wires" -> MappedCause("an object on the lines")
    "pole down" -> MappedCause("a downed pole")
    "snow storm" -> MappedCause("a snow storm")
    "substation fault" -> MappedCause("a substation fault")
    "transformer burn out" -> MappedCause("a transformer burnout")
    "transmission circuit failure" ->
      MappedCause("a transmission circuit failure")
    "tree down across our wires" -> MappedCause("a downed tree on the lines")
    "vandalism" -> MappedCause("vandalism")
    "voltage problem or overload" ->
      MappedCause("a voltage problem or overload")
    "wind storm" -> MappedCause("a wind storm")
    "wire down" -> MappedCause("a downed wire")
    "construction" -> MappedCause("construction work")
    "planned work being done on our equipment" ->
      MappedCause("planned maintenance")
    "pole replacement" -> MappedCause("a pole replacement")
    "transformer replacement" -> MappedCause("a transformer replacement")
    "work being done on our equipment" -> MappedCause("maintenance work")
    "other" | "under investigation" -> SkipCause
    lower -> UnknownCause(lower)
  }
}

fn crew_sentence(status_code: String) -> String {
  case crew.parse_crew_status(status_code) {
    None -> ""
    Some(status) ->
      case status {
        crew.NotAssigned -> "No crew has been assigned yet."
        crew.Assigned -> "A crew has been assigned."
        crew.EnRoute -> "A crew is on their way."
        crew.OnSite -> "A crew is on site."
        crew.Suspended -> "The repair is currently suspended."
      }
  }
}

fn etr_sentence(show_etr: Bool, crew_etr: Option(Int), now_ms: Int) -> String {
  case show_etr, crew_etr {
    True, Some(etr_ms) ->
      case etr_ms > now_ms {
        True ->
          "Power is expected to be restored in "
          <> duration_phrase(etr_ms - now_ms)
          <> "."
        False -> "Power restoration was expected but may have been delayed."
      }
    _, _ -> "There is no estimated restoration time yet."
  }
}
