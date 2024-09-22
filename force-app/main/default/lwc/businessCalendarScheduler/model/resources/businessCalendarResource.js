export default class BusinessCalendarResource {
  constructor(id, type, groupSortOrder) {
    this.id = id;
    this.type = type;
    this.groupSortOrder = groupSortOrder;
  }

  compareTo(otherResource) {
    return this.groupSortOrder - otherResource.groupSortOrder;
  }
}