import gleam/option.{type Option, None, Some}

pub type CrewStatus {
  NotAssigned
  Assigned
  EnRoute
  OnSite
  Suspended
}

/// Parse a crew status code string from the BC Hydro API into a typed value.
pub fn parse_crew_status(code: String) -> Option(CrewStatus) {
  case code {
    "NOT_ASSIGNED" -> Some(NotAssigned)
    "ASSIGNED" -> Some(Assigned)
    "ENROUTE" -> Some(EnRoute)
    "ONSITE" -> Some(OnSite)
    "SUSPENDED" -> Some(Suspended)
    _ -> None
  }
}

/// Returns the human-readable detail description for a crew status.
pub fn crew_status_detail(status: CrewStatus) -> String {
  case status {
    NotAssigned ->
      "A crew hasn't been assigned to the outage yet. We're working around the clock to get power restored but we don't have updates at this point. If the status was previously assigned but changed back to not-assigned, the crew may have been called away to address an immediate safety issue or emergency, other work took longer than anticipated, or additional damage was found and we had to shift resources."
    Assigned ->
      "A crew has been assigned to the area and your outage is on their list to tackle when they can."
    EnRoute -> "A crew is on their way to investigate your outage."
    OnSite ->
      "A crew is working to investigate the cause of the outage and determine the required repairs and we'll have an estimated time of restoration (ETR) soon."
    Suspended ->
      "The initial crew that arrived and assessed the problem needed different equipment. This usually means heavy equipment or materials like new poles, or additional personnel to tackle the problem and it's not currently assigned to a specific crew."
  }
}
