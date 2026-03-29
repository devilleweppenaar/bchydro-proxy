import gleam/option
import gleam/string
import gleeunit/should
import outage.{type Outage, Outage}
import summary

const now_ms = 1_700_000_000_000

fn base_outage(now: Int) -> Outage {
  Outage(
    id: "test-001",
    municipality: "Vancouver",
    area: "Downtown",
    cause: "Equipment failure",
    num_customers_out: 100,
    crew_status: "ONSITE",
    crew_status_description: "Crew on-site",
    date_off: now - 7_200_000,
    date_on: option.None,
    last_updated: now,
    region_name: "Lower Mainland",
    show_etr: False,
    crew_etr: option.None,
    latitude: 49.2827,
    longitude: -123.1207,
    polygon: [],
  )
}

pub fn no_outages_returns_no_outage_message_test() {
  summary.build_summary([], now_ms, "")
  |> should.equal("There are no outages in your area.")
}

pub fn prefix_is_prepended_to_summary_test() {
  summary.build_summary([], now_ms, "This is a test. ")
  |> should.equal("This is a test. There are no outages in your area.")
}

pub fn single_outage_known_cause_with_etr_test() {
  let o =
    Outage(
      ..base_outage(now_ms),
      cause: "Equipment failure",
      show_etr: True,
      crew_etr: option.Some(now_ms + 1_800_000),
      crew_status: "ONSITE",
      date_off: now_ms - 7_200_000,
    )
  let result = summary.build_summary([o], now_ms, "")
  string.contains(result, "equipment failure")
  |> should.be_true
  string.contains(result, "about 2 hours")
  |> should.be_true
  string.contains(result, "Power is expected to be restored")
  |> should.be_true
  string.contains(result, "A crew is on site.")
  |> should.be_true
}

pub fn single_outage_unknown_cause_test() {
  let o =
    Outage(
      ..base_outage(now_ms),
      cause: "Mysterious cause",
      show_etr: False,
      crew_status: "NOT_ASSIGNED",
      date_off: now_ms - 3_600_000,
    )
  let result = summary.build_summary([o], now_ms, "")
  string.contains(result, "The cause is listed as: mysterious cause")
  |> should.be_true
  string.contains(result, "No crew has been assigned yet.")
  |> should.be_true
}

pub fn single_outage_skip_cause_test() {
  let o =
    Outage(
      ..base_outage(now_ms),
      cause: "Other",
      show_etr: False,
      crew_status: "ASSIGNED",
      date_off: now_ms - 3_600_000,
    )
  let result = summary.build_summary([o], now_ms, "")
  string.contains(result, "A crew has been assigned.")
  |> should.be_true
  // "Other" is a SkipCause — no cause sentence should appear
  string.contains(result, "The cause is listed as")
  |> should.be_false
}

pub fn single_outage_no_etr_when_show_etr_false_test() {
  let o = Outage(..base_outage(now_ms), show_etr: False, crew_etr: option.None)
  let result = summary.build_summary([o], now_ms, "")
  string.contains(result, "There is no estimated restoration time yet.")
  |> should.be_true
}

pub fn single_outage_no_etr_when_crew_etr_null_test() {
  let o = Outage(..base_outage(now_ms), show_etr: True, crew_etr: option.None)
  let result = summary.build_summary([o], now_ms, "")
  string.contains(result, "There is no estimated restoration time yet.")
  |> should.be_true
}

pub fn single_outage_etr_in_past_test() {
  let o =
    Outage(
      ..base_outage(now_ms),
      show_etr: True,
      crew_etr: option.Some(now_ms - 60_000),
    )
  let result = summary.build_summary([o], now_ms, "")
  string.contains(
    result,
    "Power restoration was expected but may have been delayed.",
  )
  |> should.be_true
}

pub fn multiple_outages_shows_count_test() {
  let o1 = base_outage(now_ms)
  let o2 = Outage(..base_outage(now_ms), id: "test-002", num_customers_out: 50)
  let result = summary.build_summary([o1, o2], now_ms, "")
  string.contains(result, "There are 2 outages")
  |> should.be_true
}

pub fn multiple_outages_details_most_significant_test() {
  let o1 =
    Outage(
      ..base_outage(now_ms),
      id: "test-001",
      num_customers_out: 100,
      cause: "Equipment failure",
    )
  let o2 =
    Outage(
      ..base_outage(now_ms),
      id: "test-002",
      num_customers_out: 500,
      cause: "Wire down",
    )
  let result = summary.build_summary([o1, o2], now_ms, "")
  string.contains(result, "There are 2 outages")
  |> should.be_true
  string.contains(result, "a downed wire")
  |> should.be_true
}

pub fn duration_less_than_minute_test() {
  let o =
    Outage(
      ..base_outage(now_ms),
      cause: "Other",
      show_etr: False,
      crew_etr: option.None,
      date_off: now_ms - 30_000,
    )
  let result = summary.build_summary([o], now_ms, "")
  string.contains(result, "less than a minute")
  |> should.be_true
}

pub fn duration_exact_minutes_test() {
  let o =
    Outage(
      ..base_outage(now_ms),
      cause: "Other",
      show_etr: False,
      crew_etr: option.None,
      date_off: now_ms - 300_000,
    )
  let result = summary.build_summary([o], now_ms, "")
  string.contains(result, "about 5 minutes")
  |> should.be_true
}

pub fn duration_exact_one_hour_test() {
  let o =
    Outage(
      ..base_outage(now_ms),
      cause: "Other",
      show_etr: False,
      crew_etr: option.None,
      date_off: now_ms - 3_600_000,
    )
  let result = summary.build_summary([o], now_ms, "")
  string.contains(result, "about 1 hour")
  |> should.be_true
}

pub fn duration_hours_and_minutes_test() {
  let o =
    Outage(
      ..base_outage(now_ms),
      cause: "Other",
      show_etr: False,
      crew_etr: option.None,
      date_off: now_ms - 5_400_000,
    )
  let result = summary.build_summary([o], now_ms, "")
  string.contains(result, "about 1 hour and 30 minutes")
  |> should.be_true
}

pub fn duration_plural_hours_test() {
  let o =
    Outage(
      ..base_outage(now_ms),
      cause: "Other",
      show_etr: False,
      crew_etr: option.None,
      date_off: now_ms - 7_200_000,
    )
  let result = summary.build_summary([o], now_ms, "")
  string.contains(result, "about 2 hours")
  |> should.be_true
}

pub fn duration_days_test() {
  let o =
    Outage(
      ..base_outage(now_ms),
      cause: "Other",
      show_etr: False,
      crew_etr: option.None,
      date_off: now_ms - 172_800_000,
    )
  let result = summary.build_summary([o], now_ms, "")
  string.contains(result, "about 2 days")
  |> should.be_true
}
