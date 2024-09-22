import CALL2_OBJECT from '@salesforce/schema/Call2_vod__c';
import MyAccountsButtonController from '../myAccountsButtonController';

export default class ScheduleCallActionController extends MyAccountsButtonController {
  static MESSAGE_REQUEST = MyAccountsButtonController.createMessageRequest().addRequest(
    'SCHEDULE_CALL',
    'MyAccounts',
    'Schedule Call',
    'scheduleCallBtn'
  ).addRequest(
    'My Calls',
    'Callplan',
    'inactive message',
    'myCallsLabel'
  );

  static REQUIRED_OBJECTS = [CALL2_OBJECT.objectApiName];

  static NAV_ITEMS = ['My_Schedule_vod'];

  getLabel(messageMap) {
    return messageMap.scheduleCallBtn;
  }

  isVisible(objectInfoMap, settings, navItems, messageMap) {
    const hasCreateAccessToCall = objectInfoMap?.[CALL2_OBJECT.objectApiName]?.createable;
    const isTabAvailable = navItems && navItems instanceof Map && navItems.get('My_Schedule_vod');
    const isTabAvailableInLightning = isTabAvailable && navItems.get('My_Schedule_vod')?.availableInLightning;
    const doesTabLabelMatchVeevaMatch = isTabAvailable && navItems.get('My_Schedule_vod')?.label === messageMap.myCallsLabel;

    return hasCreateAccessToCall && isTabAvailableInLightning && doesTabLabelMatchVeevaMatch;
  }

  get disabled() {
    return !this.selectedAccounts || this.selectedAccounts.length === 0;
  }

  async createActionEvents() {
    return [new CustomEvent('schedulecall')];
  }
}