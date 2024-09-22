import BaseWarningHandler from './baseWarningHandler';

export default class AttendeeWarningHandler extends BaseWarningHandler {
  get idField() {
    return 'speakerId';
  }

  get nameField() {
    return 'speakerName';
  }

  get header() {
    return this.messages.POTENTIAL_SPEAKER_WARNING_TITLE;
  }

  get subheader() {
    return this.messages.POTENTIAL_SPEAKER_WARNING_SUBTITLE;
  }
}