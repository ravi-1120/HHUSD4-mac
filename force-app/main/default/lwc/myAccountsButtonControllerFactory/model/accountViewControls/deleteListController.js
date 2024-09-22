import ACCOUNT_LIST_OBJECT from '@salesforce/schema/Account_List_vod__c';
import ACCOUNT_LIST_ITEM_OBJECT from '@salesforce/schema/Account_List_Item_vod__c';

import MyAccountsButtonController from '../myAccountsButtonController';

export default class DeleteListController extends MyAccountsButtonController {
  static REQUIRED_OBJECTS = [ACCOUNT_LIST_OBJECT.objectApiName, ACCOUNT_LIST_ITEM_OBJECT.objectApiName];
  static MESSAGE_REQUEST = MyAccountsButtonController.createMessageRequest().addRequest('DELETE', 'Common', 'Delete', 'deleteLabel');

  getLabel(messageMap) {
    return messageMap.deleteLabel;
  }

  isVisible(objectInfoMap) {
    return DeleteListController.REQUIRED_OBJECTS.map(objectApiName => objectInfoMap[objectApiName]).every(objectInfo => objectInfo?.deletable);
  }

  createEvents() {
    return [new CustomEvent('deleteview')];
  }
}