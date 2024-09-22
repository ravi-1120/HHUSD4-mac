import ACCOUNT_LIST_ITEM_OBJECT from '@salesforce/schema/Account_List_Item_vod__c';

import MyAccountsButtonController from '../myAccountsButtonController';

export default class AddToListController extends MyAccountsButtonController {
  static REQUIRED_OBJECTS = [ACCOUNT_LIST_ITEM_OBJECT.objectApiName];
  static MESSAGE_REQUEST = MyAccountsButtonController.createMessageRequest().addRequest('ADD_TO_LIST', 'Common', 'Add to List', 'addToListLabel');

  hasLists = false;

  get disabled() {
    return !this.selectedAccounts || this.selectedAccounts.length === 0 || !this.hasLists;
  }

  getLabel(messageMap) {
    return messageMap.addToListLabel;
  }

  isVisible(objectInfoMap) {
    return objectInfoMap[ACCOUNT_LIST_ITEM_OBJECT.objectApiName]?.createable;
  }

  createEvents() {
    const accountIdSet = new Set(this.selectedAccounts.map(selectedAccount => selectedAccount['Account-Id']));
    return [new CustomEvent('addtolist', { detail: { accountIds: [...accountIdSet] } })];
  }
}