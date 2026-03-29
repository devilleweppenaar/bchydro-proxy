import gleam/list
import gleam/option
import gleam/string
import gleeunit/should
import test_mode

const now_ms = 1_748_000_000_000

// --- check_test_mode ---

pub fn test_mode_disabled_when_env_false_test() {
  test_mode.check_test_mode(False, "outage")
  |> should.equal(test_mode.TestModeDisabled)
}

pub fn test_mode_disabled_ignores_invalid_param_test() {
  test_mode.check_test_mode(False, "invalid")
  |> should.equal(test_mode.TestModeDisabled)
}

pub fn test_mode_disabled_ignores_empty_param_test() {
  test_mode.check_test_mode(False, "")
  |> should.equal(test_mode.TestModeDisabled)
}

pub fn test_mode_invalid_param_when_enabled_and_unknown_test() {
  test_mode.check_test_mode(True, "unknown")
  |> should.equal(test_mode.TestModeInvalidParam)
}

pub fn test_mode_invalid_param_when_enabled_and_empty_test() {
  test_mode.check_test_mode(True, "")
  |> should.equal(test_mode.TestModeInvalidParam)
}

pub fn test_mode_active_outage_test() {
  test_mode.check_test_mode(True, "outage")
  |> should.equal(test_mode.TestModeActive(test_mode.SingleOutage))
}

pub fn test_mode_active_no_outage_test() {
  test_mode.check_test_mode(True, "no-outage")
  |> should.equal(test_mode.TestModeActive(test_mode.NoOutage))
}

pub fn test_mode_active_multiple_test() {
  test_mode.check_test_mode(True, "multiple")
  |> should.equal(test_mode.TestModeActive(test_mode.MultipleOutages))
}

pub fn test_mode_error_when_enabled_test() {
  test_mode.check_test_mode(True, "error")
  |> should.equal(test_mode.TestModeError)
}

pub fn test_mode_error_disabled_ignores_error_param_test() {
  test_mode.check_test_mode(False, "error")
  |> should.equal(test_mode.TestModeDisabled)
}

// --- test_outages: SingleOutage ---

pub fn single_outage_returns_one_outage_test() {
  test_mode.test_outages(test_mode.SingleOutage, now_ms)
  |> list.length()
  |> should.equal(1)
}

pub fn single_outage_cause_has_no_test_marker_test() {
  let assert [outage] = test_mode.test_outages(test_mode.SingleOutage, now_ms)
  string.contains(outage.cause, "(TEST DATA)")
  |> should.be_false()
}

pub fn single_outage_covers_vancouver_test() {
  let assert [outage] = test_mode.test_outages(test_mode.SingleOutage, now_ms)
  should.equal(outage.municipality, "Vancouver")
}

pub fn single_outage_has_polygon_test() {
  let assert [outage] = test_mode.test_outages(test_mode.SingleOutage, now_ms)
  outage.polygon
  |> list.is_empty()
  |> should.be_false()
}

// --- test_outages: NoOutage ---

pub fn no_outage_returns_one_outage_test() {
  test_mode.test_outages(test_mode.NoOutage, now_ms)
  |> list.length()
  |> should.equal(1)
}

pub fn no_outage_cause_has_no_test_marker_test() {
  let assert [outage] = test_mode.test_outages(test_mode.NoOutage, now_ms)
  string.contains(outage.cause, "(TEST DATA)")
  |> should.be_false()
}

pub fn no_outage_is_victoria_not_vancouver_test() {
  let assert [outage] = test_mode.test_outages(test_mode.NoOutage, now_ms)
  should.equal(outage.municipality, "Victoria")
}

// --- test_outages: MultipleOutages ---

pub fn multiple_outages_returns_three_outages_test() {
  test_mode.test_outages(test_mode.MultipleOutages, now_ms)
  |> list.length()
  |> should.equal(3)
}

pub fn multiple_outages_causes_have_no_test_marker_test() {
  test_mode.test_outages(test_mode.MultipleOutages, now_ms)
  |> list.all(fn(o) { !string.contains(o.cause, "(TEST DATA)") })
  |> should.be_true()
}

pub fn multiple_outages_has_kelowna_test() {
  let outages = test_mode.test_outages(test_mode.MultipleOutages, now_ms)
  outages
  |> list.any(fn(o) { o.municipality == "Kelowna" })
  |> should.be_true()
}

pub fn multiple_outages_kelowna_has_no_crew_etr_test() {
  let outages = test_mode.test_outages(test_mode.MultipleOutages, now_ms)
  let kelowna =
    outages
    |> list.find(fn(o) { o.municipality == "Kelowna" })
  case kelowna {
    Error(_) -> should.fail()
    Ok(o) -> o.crew_etr |> should.equal(option.None)
  }
}
