import crew
import gleam/option
import gleeunit/should

// --- parse_crew_status ---

pub fn parse_crew_status_not_assigned_test() {
  crew.parse_crew_status("NOT_ASSIGNED")
  |> should.equal(option.Some(crew.NotAssigned))
}

pub fn parse_crew_status_assigned_test() {
  crew.parse_crew_status("ASSIGNED")
  |> should.equal(option.Some(crew.Assigned))
}

pub fn parse_crew_status_enroute_test() {
  crew.parse_crew_status("ENROUTE")
  |> should.equal(option.Some(crew.EnRoute))
}

pub fn parse_crew_status_onsite_test() {
  crew.parse_crew_status("ONSITE")
  |> should.equal(option.Some(crew.OnSite))
}

pub fn parse_crew_status_suspended_test() {
  crew.parse_crew_status("SUSPENDED")
  |> should.equal(option.Some(crew.Suspended))
}

pub fn parse_crew_status_unknown_returns_none_test() {
  crew.parse_crew_status("UNKNOWN")
  |> should.equal(option.None)
}

pub fn parse_crew_status_empty_returns_none_test() {
  crew.parse_crew_status("")
  |> should.equal(option.None)
}

pub fn parse_crew_status_is_case_sensitive_test() {
  crew.parse_crew_status("onsite")
  |> should.equal(option.None)
}

// --- crew_status_detail ---

pub fn crew_status_detail_not_assigned_is_non_empty_test() {
  crew.crew_status_detail(crew.NotAssigned)
  |> should.not_equal("")
}

pub fn crew_status_detail_assigned_is_non_empty_test() {
  crew.crew_status_detail(crew.Assigned)
  |> should.not_equal("")
}

pub fn crew_status_detail_enroute_is_non_empty_test() {
  crew.crew_status_detail(crew.EnRoute)
  |> should.not_equal("")
}

pub fn crew_status_detail_onsite_is_non_empty_test() {
  crew.crew_status_detail(crew.OnSite)
  |> should.not_equal("")
}

pub fn crew_status_detail_suspended_is_non_empty_test() {
  crew.crew_status_detail(crew.Suspended)
  |> should.not_equal("")
}

pub fn crew_status_detail_not_assigned_content_test() {
  crew.crew_status_detail(crew.NotAssigned)
  |> should.equal(
    "A crew hasn't been assigned to the outage yet. We're working around the clock to get power restored but we don't have updates at this point. If the status was previously assigned but changed back to not-assigned, the crew may have been called away to address an immediate safety issue or emergency, other work took longer than anticipated, or additional damage was found and we had to shift resources.",
  )
}

pub fn crew_status_detail_enroute_content_test() {
  crew.crew_status_detail(crew.EnRoute)
  |> should.equal("A crew is on their way to investigate your outage.")
}

pub fn crew_status_detail_assigned_content_test() {
  crew.crew_status_detail(crew.Assigned)
  |> should.equal(
    "A crew has been assigned to the area and your outage is on their list to tackle when they can.",
  )
}

pub fn crew_status_detail_onsite_content_test() {
  crew.crew_status_detail(crew.OnSite)
  |> should.equal(
    "A crew is working to investigate the cause of the outage and determine the required repairs and we'll have an estimated time of restoration (ETR) soon.",
  )
}

pub fn crew_status_detail_suspended_content_test() {
  crew.crew_status_detail(crew.Suspended)
  |> should.equal(
    "The initial crew that arrived and assessed the problem needed different equipment. This usually means heavy equipment or materials like new poles, or additional personnel to tackle the problem and it's not currently assigned to a specific crew.",
  )
}
