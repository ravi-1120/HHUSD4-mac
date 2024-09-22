import { BusRuleConstant } from 'c/emBusRuleUtils';
import EmEventConstant from 'c/emEventConstant';

import eventsManagementChannel from '@salesforce/messageChannel/Events_Management_Channel_vod__c';
import { publish, createMessageContext } from 'lightning/messageService';
import EVENT_SPEAKER from '@salesforce/schema/EM_Event_Speaker_vod__c';
import SPEAKER_NAME from '@salesforce/schema/EM_Event_Speaker_vod__c.Speaker_Name_vod__c';

import BaseViolationHandler from './baseViolationHandler';

export default class PerSpeakerViolationHandler extends BaseViolationHandler {
  get objectApiName() {
    return EVENT_SPEAKER.objectApiName;
  }

  get nameField() {
    return SPEAKER_NAME.fieldApiName;
  }

  get header() {
    return this.isHardWarningScreen
      ? this.messages.PER_SPEAKER_ATTENDANCE_HARD_WARNING_TITLE
      : this.messages.PER_SPEAKER_ATTENDANCE_SOFT_WARNING_TITLE;
  }

  get showCheckbox() {
    return !this.isHardWarningScreen && this.page === 1;
  }

  get subheader() {
    let subheader;
    if (this.isHardWarningScreen) {
      subheader = this.messages.PER_SPEAKER_ATTENDANCE_HARD_WARNING_SUBTITLE;
    } else if (this.page === 2) {
      subheader = this.messages.PER_SPEAKER_ATTENDANCE_SOFT_WARNING_SUBTITLE2;
    } else {
      subheader = this.messages.PER_SPEAKER_ATTENDANCE_SOFT_WARNING_SUBTITLE;
    }
    return subheader;
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

  get buttonHandlers() {
    return {
      ...super.buttonHandlers,
      [BusRuleConstant.ACTION_NAME.REMOVE_ALL_CONTINUE]: this.removeAllEventSpeakers,
      [BusRuleConstant.ACTION_NAME.REMOVE_SELECTED_CONTINUE]: this.removeSelectedEventSpeakers,
    };
  }

  // eslint-disable-next-line no-unused-vars
  async removeAllEventSpeakers(buttonName, overrides, checkedRows) {
    const speakerIdsToRemove = new Set();
    this.recordsToDisplay.forEach(rule => {
      speakerIdsToRemove.add(rule.EM_Event_Speaker_vod__c.Id);
    });

    await this.removeEventSpeakers([...speakerIdsToRemove]);

    return {
      nextStep: BusRuleConstant.NEXT_STEP.CONTINUE,
      refreshPerEvent: true,
      remainingRecords: this.violations.filter(rule => !speakerIdsToRemove.has(rule.EM_Event_Speaker_vod__c.Id)),
    };
  }

  async removeSelectedEventSpeakers(buttonName, overrides, checkedRows) {
    await this.removeEventSpeakers(checkedRows);
    const remainingRecords = this.violations.filter(
      rule =>
        !checkedRows.includes(rule.EM_Event_Speaker_vod__c.Id) &&
        rule.EM_Event_Override_vod__c.Comment_Box_vod__c !== BusRuleConstant.COMMENT_TYPE.HIDDEN
    );
    return {
      nextStep: remainingRecords.length ? BusRuleConstant.NEXT_STEP.PAGE_TWO : BusRuleConstant.NEXT_STEP.CONTINUE,
      refreshPerEvent: checkedRows.length > 0,
      remainingRecords,
    };
  }

  async removeEventSpeakers(eventSpeakerIds) {
    if (eventSpeakerIds.length) {
      await this.busRuleDataSvc.removeEventSpeakers(eventSpeakerIds);
      const payload = {
        key: EmEventConstant.REFRESH_RELATED_LIST,
        parentId: this.eventId,
        relationship: 'EM_Event_Speaker_vod__r',
      };
      publish(createMessageContext(), eventsManagementChannel, payload);
    }
  }
}