import gleam/option.{None, Some}
import outage.{type Outage, Outage}

pub type TestScenario {
  SingleOutage
  NoOutage
  MultipleOutages
}

pub type TestModeResult {
  /// TEST_MODE env var is false — ignore test param, use normal request flow.
  TestModeDisabled
  /// TEST_MODE is true but the test param is not a recognised scenario.
  TestModeInvalidParam
  /// TEST_MODE is true and the scenario is valid.
  TestModeActive(TestScenario)
  /// TEST_MODE is true and ?test=error — returns a simulated error response.
  TestModeError
}

/// Determine the test mode result given the TEST_MODE flag and the ?test= param value.
pub fn check_test_mode(is_enabled: Bool, test_param: String) -> TestModeResult {
  case is_enabled, test_param {
    False, _ -> TestModeDisabled
    True, "outage" -> TestModeActive(SingleOutage)
    True, "no-outage" -> TestModeActive(NoOutage)
    True, "multiple" -> TestModeActive(MultipleOutages)
    True, "error" -> TestModeError
    True, _ -> TestModeInvalidParam
  }
}

/// Returns mock outage data for the given scenario.
/// `now_ms` should be the current Unix timestamp in milliseconds.
pub fn test_outages(scenario: TestScenario, now_ms: Int) -> List(Outage) {
  let one_hour = 3_600_000
  let two_hours = 7_200_000
  let date_off = now_ms - one_hour
  let date_on = Some(now_ms + two_hours)

  case scenario {
    SingleOutage -> [
      Outage(
        id: "test-outage-001",
        municipality: "Vancouver",
        area: "Downtown",
        cause: "Equipment failure",
        num_customers_out: 1500,
        crew_status: "ONSITE",
        crew_status_description: "Crew on-site",
        date_off:,
        date_on:,
        last_updated: now_ms,
        region_name: "Lower Mainland",
        show_etr: True,
        crew_etr: date_on,
        latitude: 49.2827,
        longitude: -123.1207,
        polygon: vancouver_downtown_polygon(),
      ),
    ]

    NoOutage -> [
      Outage(
        id: "test-outage-002",
        municipality: "Victoria",
        area: "James Bay",
        cause: "Tree down across our wires",
        num_customers_out: 245,
        crew_status: "ENROUTE",
        crew_status_description: "Crew en route",
        date_off:,
        date_on:,
        last_updated: now_ms,
        region_name: "Vancouver Island",
        show_etr: True,
        crew_etr: date_on,
        latitude: 48.4284,
        longitude: -123.3656,
        polygon: victoria_polygon(),
      ),
    ]

    MultipleOutages -> [
      Outage(
        id: "test-outage-003",
        municipality: "Vancouver",
        area: "Downtown Core",
        cause: "Cable fault",
        num_customers_out: 850,
        crew_status: "ONSITE",
        crew_status_description: "Crew on-site",
        date_off:,
        date_on:,
        last_updated: now_ms,
        region_name: "Lower Mainland",
        show_etr: True,
        crew_etr: date_on,
        latitude: 49.2827,
        longitude: -123.1207,
        polygon: vancouver_downtown_polygon(),
      ),
      Outage(
        id: "test-outage-004",
        municipality: "Vancouver",
        area: "West End",
        cause: "Motor vehicle accident",
        num_customers_out: 420,
        crew_status: "ASSIGNED",
        crew_status_description: "Crew assigned",
        date_off: now_ms - one_hour - 1_800_000,
        date_on: Some(now_ms + two_hours + 1_800_000),
        last_updated: now_ms - 900_000,
        region_name: "Lower Mainland",
        show_etr: True,
        crew_etr: Some(now_ms + two_hours + 1_800_000),
        latitude: 49.285,
        longitude: -123.13,
        polygon: [
          -123.16, 49.275, -123.12, 49.275, -123.12, 49.295, -123.16, 49.295,
          -123.16, 49.275,
        ],
      ),
      Outage(
        id: "test-outage-005",
        municipality: "Kelowna",
        area: "Rutland",
        cause: "Planned work being done on our equipment",
        num_customers_out: 125,
        crew_status: "NOT_ASSIGNED",
        crew_status_description: "Not assigned",
        date_off:,
        date_on:,
        last_updated: now_ms,
        region_name: "Interior",
        show_etr: False,
        crew_etr: None,
        latitude: 49.888,
        longitude: -119.496,
        polygon: kelowna_polygon(),
      ),
    ]
  }
}

fn vancouver_downtown_polygon() -> List(Float) {
  [-123.15, 49.27, -123.1, 49.27, -123.1, 49.29, -123.15, 49.29, -123.15, 49.27]
}

fn victoria_polygon() -> List(Float) {
  [-123.4, 48.4, -123.3, 48.4, -123.3, 48.45, -123.4, 48.45, -123.4, 48.4]
}

fn kelowna_polygon() -> List(Float) {
  [
    -119.55, 49.85, -119.45, 49.85, -119.45, 49.93, -119.55, 49.93, -119.55,
    49.85,
  ]
}
