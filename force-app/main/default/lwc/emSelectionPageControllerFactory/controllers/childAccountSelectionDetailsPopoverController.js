import AttendeeSelectionDetailsPopoverController from './attendeeSelectionDetailsPopoverController';

export default class ChildAccountSelectionDetailsPopoverController extends AttendeeSelectionDetailsPopoverController {
  getIdForDetails(record) {
    return record.childId ?? super.getIdForDetails(record);
  }
}