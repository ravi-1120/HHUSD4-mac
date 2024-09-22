import VIEW_OBJECT from '@salesforce/schema/View_vod__c';

import hasViewSetupPermission from '@salesforce/userPermission/ViewSetup';

import MyAccountsButtonController from '../myAccountsButtonController';

export default class DeleteViewController extends MyAccountsButtonController {
  static REQUIRED_OBJECTS = [VIEW_OBJECT.objectApiName];
  static MESSAGE_REQUEST = MyAccountsButtonController.createMessageRequest().addRequest('DELETE', 'Common', 'Delete', 'deleteLabel');

  isViewOwner = false;

  getLabel(messageMap) {
    return messageMap.deleteLabel;
  }

  isVisible(objectInfoMap) {
    return objectInfoMap[VIEW_OBJECT.objectApiName]?.deletable;
  }

  get disabled() {
    const isNotOwner = !this.isViewOwner;
    return isNotOwner && !hasViewSetupPermission
  }

  createEvents() {
    return [new CustomEvent('deleteview')];
  }
}