import ACCOUNT_LIST_ITEM_OBJECT from '@salesforce/schema/Account_List_Item_vod__c';

import MyAccountsButtonController from '../myAccountsButtonController';

export default class RemoveFromListController extends MyAccountsButtonController {
  static REQUIRED_OBJECTS = [ACCOUNT_LIST_ITEM_OBJECT.objectApiName];
  static MESSAGE_REQUEST = MyAccountsButtonController.createMessageRequest().addRequest(
    'REMOVE_FROM_LIST',
    'TABLET',
    'Remove from List',
    'removeFromListLabel'
  );

  get disabled() {
    return !this.selectedAccounts || this.selectedAccounts.length === 0;
  }

  getLabel(messageMap) {
    return messageMap.removeFromListLabel;
  }

  isVisible(objectInfoMap) {
    return objectInfoMap[ACCOUNT_LIST_ITEM_OBJECT.objectApiName]?.deletable;
  }

  createEvents() {
    const accountIdsToRemove = new Set(this.selectedAccounts.map(selectedAccount => selectedAccount['Account-Id']));
    return [
      new CustomEvent('removeaccounts', {
        detail: {
          accountIds: [...accountIdsToRemove],
          rowIds: this.selectedAccounts.map(selectedAccount => selectedAccount.id), // This is the id that Bryntum will use for each row internally
        },
      }),
    ];
  }
}