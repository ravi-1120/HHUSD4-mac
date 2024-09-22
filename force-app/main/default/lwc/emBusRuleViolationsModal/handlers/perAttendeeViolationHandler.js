import { BusRuleConstant } from 'c/emBusRuleUtils';
import EmEventConstant from 'c/emEventConstant';

import eventsManagementChannel from '@salesforce/messageChannel/Events_Management_Channel_vod__c';
import { publish, createMessageContext } from 'lightning/messageService';
import ATTENDEE from '@salesforce/schema/EM_Attendee_vod__c';
import ATTENDEE_NAME from '@salesforce/schema/EM_Attendee_vod__c.Attendee_Name_vod__c';

import BaseViolationHandler from './baseViolationHandler';

export default class PerAttendeeViolationHandler extends BaseViolationHandler {
  get objectApiName() {
    return ATTENDEE.objectApiName;
  }

  get nameField() {
    return ATTENDEE_NAME.fieldApiName;
  }

  get header() {
    return this.isHardWarningScreen ? this.messages.PER_ATTENDEE_HARD_WARNING_TITLE : this.messages.PER_ATTENDEE_SOFT_WARNING_TITLE;
  }

  get buttons() {
    const buttons = [];
    if (this.isHardWarningScreen) {
      buttons.push({ name: BusRuleConstant.ACTION_NAME.REMOVE_ALL_CONTINUE, label: this.messages.REMOVE_AND_CONTINUE, variant: 'brand' });
    } else if (this.page === 2) {
      buttons.push({ name: BusRuleConstant.ACTION_NAME.SAVE_OVERRIDES_EXIT, label: this.messages.SAVE_COMMENTS });
      buttons.push({ name: BusRuleConstant.ACTION_NAME.SAVE_OVERRIDES_CONTINUE, label: this.messages.CONTINUE, variant: 'brand' });
    } else {
      buttons.push({ name: BusRuleConstant.ACTION_NAME.REMOVE_SELECTED_CONTINUE, label: this.messages.CONTINUE, variant: 'brand' });
    }
    return buttons;
  }

  get showCheckbox() {
    return !this.isHardWarningScreen && this.page === 1;
  }

  get subheader() {
    let subheader;
    if (this.isHardWarningScreen) {
      subheader = this.messages.PER_ATTENDEE_HARD_WARNING_SUBTITLE;
    } else if (this.page === 2) {
      subheader = this.messages.PER_ATTENDEE_SOFT_WARNING_SUBTITLE2;
    } else {
      subheader = this.messages.PER_ATTENDEE_SOFT_WARNING_SUBTITLE;
    }
    return subheader;
  }

  get buttonHandlers() {
    return {
      ...super.buttonHandlers,
      [BusRuleConstant.ACTION_NAME.REMOVE_ALL_CONTINUE]: this.removeAllAttendees,
      [BusRuleConstant.ACTION_NAME.REMOVE_SELECTED_CONTINUE]: this.removeSelectedAttendees,
    };
  }

  // eslint-disable-next-line no-unused-vars
  async removeAllAttendees(buttonName, overrides, checkedRows) {
    const attendeeIdsToRemove = new Set();
    this.recordsToDisplay.forEach(rule => {
      attendeeIdsToRemove.add(rule.EM_Attendee_vod__c.Id);
    });

    await this.removeAttendees([...attendeeIdsToRemove]);

    return {
      nextStep: BusRuleConstant.NEXT_STEP.CONTINUE,
      refreshPerEvent: true,
      remainingRecords: this.violations.filter(rule => !attendeeIdsToRemove.has(rule.EM_Attendee_vod__c.Id)),
    };
  }

  async removeSelectedAttendees(buttonName, overrides, checkedRows) {
    await this.removeAttendees(checkedRows);
    const remainingRecords = this.violations.filter(
      rule =>
        !checkedRows.includes(rule.EM_Attendee_vod__c.Id) && rule.EM_Event_Override_vod__c.Comment_Box_vod__c !== BusRuleConstant.COMMENT_TYPE.HIDDEN
    );
    return {
      nextStep: remainingRecords.length ? BusRuleConstant.NEXT_STEP.PAGE_TWO : BusRuleConstant.NEXT_STEP.CONTINUE,
      refreshPerEvent: checkedRows.length > 0,
      remainingRecords,
    };
  }

  async removeAttendees(attendeeIds) {
    if (attendeeIds.length) {
      await this.busRuleDataSvc.removeAttendees(attendeeIds);
      const payload = {
        key: EmEventConstant.REFRESH_RELATED_LIST,
        parentId: this.eventId,
        relationship: 'EM_Attendee_Event_vod__r',
      };
      publish(createMessageContext(), eventsManagementChannel, payload);
    }
  }
}