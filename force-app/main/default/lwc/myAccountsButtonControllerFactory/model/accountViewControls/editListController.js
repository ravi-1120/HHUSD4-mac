import ACCOUNT_LIST_OBJECT from '@salesforce/schema/Account_List_vod__c';
import VIEW_OBJECT from '@salesforce/schema/View_vod__c';

import MyAccountsButtonController from '../myAccountsButtonController';

export default class EditListController extends MyAccountsButtonController {
  static REQUIRED_OBJECTS = [VIEW_OBJECT.objectApiName, ACCOUNT_LIST_OBJECT.objectApiName];
  static MESSAGE_REQUEST = MyAccountsButtonController.createMessageRequest().addRequest('Edit', 'Common', 'Edit', 'editLabel');

  constructor(objectInfoMap, messageMap, settings) {
    super(objectInfoMap, messageMap, settings);
    this.objectInfoMap = objectInfoMap;
  }

  getLabel(messageMap) {
    return messageMap.editLabel;
  }

  get disabled() {
    return !this.objectInfoMap[ACCOUNT_LIST_OBJECT.objectApiName]?.updateable;
  }

  isVisible(objectInfoMap) {
    return objectInfoMap[VIEW_OBJECT.objectApiName]?.updateable || objectInfoMap[ACCOUNT_LIST_OBJECT.objectApiName]?.updateable;
  }

  createEvents() {
    return [new CustomEvent('editlist')];
  }
}