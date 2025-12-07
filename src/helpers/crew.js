/**
 * Map crew status codes to detailed human-readable descriptions
 * @param {string} crewStatus - The crew status code
 * @returns {string|null} - Human-readable description or null if status not found
 */
export function getCrewStatusDetail(crewStatus) {
  const statusMap = {
    NOT_ASSIGNED:
      "A crew hasn't been assigned to the outage yet. We're working around the clock to get power restored but we don't have updates at this point. If the status was previously assigned but changed back to not-assigned, the crew may have been called away to address an immediate safety issue or emergency, other work took longer than anticipated, or additional damage was found and we had to shift resources.",
    ASSIGNED:
      "A crew has been assigned to the area and your outage is on their list to tackle when they can.",
    ENROUTE: "A crew is on their way to investigate your outage.",
    ONSITE:
      "A crew is working to investigate the cause of the outage and determine the required repairs and we'll have an estimated time of restoration (ETR) soon.",
    SUSPENDED:
      "The initial crew that arrived and assessed the problem needed different equipment. This usually means heavy equipment or materials like new poles, or additional personnel to tackle the problem and it's not currently assigned to a specific crew.",
  };

  return statusMap[crewStatus] || null;
}
