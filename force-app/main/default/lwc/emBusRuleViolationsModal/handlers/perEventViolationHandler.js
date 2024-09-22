import BaseViolationHandler from './baseViolationHandler';

export default class PerEventViolationHandler extends BaseViolationHandler {
  get header() {
    return this.isHardWarningScreen ? this.messages.PER_EVENT_HARD_WARNING_TITLE : this.messages.PER_EVENT_SOFT_WARNING_TITLE;
  }

  get subheader() {
    return this.isHardWarningScreen ? this.messages.PER_EVENT_HARD_WARNING_SUBTITLE : this.messages.PER_EVENT_SOFT_WARNING_SUBTITLE;
  }
}