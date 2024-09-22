export default class BusinessCalendarEvent {
    constructor(name, description, startDateTime, endDateTime, color, resourceId, tooltip) {
      this.name = name;
      this.description = description;
      this.startDate = startDateTime;
      this.endDate = endDateTime;
      this.eventColor = color;
      this.resourceId = resourceId;
      this.tooltip = tooltip;
    }
  
    get tooltipDomConfig() {
      return this.tooltip.domConfig;
    }
  }