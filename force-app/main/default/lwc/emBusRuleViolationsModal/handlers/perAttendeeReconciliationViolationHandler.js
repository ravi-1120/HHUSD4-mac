import { BusRuleConstant } from 'c/emBusRuleUtils';
import PerAttendeeViolationHandler from './perAttendeeViolationHandler';

export default class PerAttendeeReconciliationViolationHandler extends PerAttendeeViolationHandler {
  get buttons() {
    let button;
    if (this.isHardWarningScreen) {
      button = { name: BusRuleConstant.ACTION_NAME.REJECT_REGISTRANT, label: this.messages.REJECT_REGISTRANT, variant: 'brand' };
    } else if (this.page === 2) {
      button = { name: BusRuleConstant.ACTION_NAME.SAVE_OVERRIDES_CONTINUE, label: this.messages.CONFIRM_MATCH, variant: 'brand' };
    } else {
      button = { name: BusRuleConstant.ACTION_NAME.CONFIRM_MATCH, label: this.messages.CONFIRM_MATCH, variant: 'brand' };
    }
    return [button];
  }

  get showCheckbox() {
    return false;
  }

  generateCommentRow(record) {
    const commentRow = super.generateCommentRow(record);
    commentRow.commentBox = commentRow.commentBox && this.page === 2;
    return commentRow;
  }

  get subheader() {
    let subheader;
    if (this.isHardWarningScreen) {
      subheader = this.messages.EM_RULE_PER_ATTENDEE_ATTENDANCE_RECONCILIATION_HARD_WARNING_SUBTITLE;
    } else if (this.page === 2) {
      subheader = this.messages.EM_RULE_PER_ATTENDEE_ATTENDANCE_RECONCILIATION_SOFT_WARNING_SUBTITLE2;
    } else {
      subheader = this.messages.EM_RULE_PER_ATTENDEE_ATTENDANCE_RECONCILIATION_SOFT_WARNING_SUBTITLE;
    }
    return subheader;
  }

  get buttonHandlers() {
    return {
      ...super.buttonHandlers,
      [BusRuleConstant.ACTION_NAME.REJECT_REGISTRANT]: this.rejectRegistrant,
      [BusRuleConstant.ACTION_NAME.CONFIRM_MATCH]: this.removeSelectedAttendees,
    };
  }

  // eslint-disable-next-line no-unused-vars
  rejectRegistrant(buttonName, overrides, checkedRows) {
    return {
      nextStep: BusRuleConstant.NEXT_STEP.CONTINUE,
      refreshPerEvent: false,
      remainingRecords: [],
    };
  }
}