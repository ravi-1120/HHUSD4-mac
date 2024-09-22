import ACCOUNT_LIST_OBJECT from '@salesforce/schema/Account_List_vod__c';
import ACCOUNT_LIST_ITEM_OBJECT from '@salesforce/schema/Account_List_Item_vod__c';

import MyAccountsButtonController from '../myAccountsButtonController';

export default class CreateNewListController extends MyAccountsButtonController {
  static REQUIRED_OBJECTS = [ACCOUNT_LIST_OBJECT.objectApiName, ACCOUNT_LIST_ITEM_OBJECT.objectApiName];
  static MESSAGE_REQUEST = MyAccountsButtonController.createMessageRequest().addRequest(
    'CREATE_NEW_LIST',
    'Common',
    'Create New List',
    'createNewListLabel'
  );

  get disabled() {
    return !this.selectedAccounts || this.selectedAccounts.length === 0;
  }

  getLabel(messageMap) {
    return messageMap.createNewListLabel;
  }

  isVisible(objectInfoMap) {
    return CreateNewListController.REQUIRED_OBJECTS.map(objectApiName => objectInfoMap[objectApiName]).every(objectInfo => objectInfo?.createable);
  }

  createEvents() {
    const accountIdSet = new Set(this.selectedAccounts.map(selectedAccount => selectedAccount['Account-Id']));
    return [new CustomEvent('createnewlist', { detail: { accountIds: [...accountIdSet] } })];
  }
}