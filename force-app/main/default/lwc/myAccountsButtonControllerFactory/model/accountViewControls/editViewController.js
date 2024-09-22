import ACCOUNT_LIST_OBJECT from '@salesforce/schema/Account_List_vod__c';
import VIEW_OBJECT from '@salesforce/schema/View_vod__c';

import hasViewSetupPermission from '@salesforce/userPermission/ViewSetup';

import MyAccountsButtonController from '../myAccountsButtonController';

export default class EditViewController extends MyAccountsButtonController {
  static REQUIRED_OBJECTS = [VIEW_OBJECT.objectApiName, ACCOUNT_LIST_OBJECT.objectApiName];
  static MESSAGE_REQUEST = MyAccountsButtonController.createMessageRequest().addRequest('Edit', 'Common', 'Edit', 'editLabel');

  isViewOwner = false;

  constructor(objectInfoMap, messageMap, settings) {
    super(objectInfoMap, messageMap, settings);
    this.objectInfoMap = objectInfoMap;
  }

  getLabel(messageMap) {
    return messageMap.editLabel;
  }

  isVisible(objectInfoMap) {
    return objectInfoMap[VIEW_OBJECT.objectApiName]?.updateable || objectInfoMap[ACCOUNT_LIST_OBJECT.objectApiName]?.updateable;
  }

  get disabled() {
    const cannotUpdateView = !this.objectInfoMap[VIEW_OBJECT.objectApiName]?.updateable;
    const isNotOwner = !this.isViewOwner;
    const isNotOwnerAndMissingViewSetupPermission = isNotOwner && !hasViewSetupPermission;
    return cannotUpdateView || isNotOwnerAndMissingViewSetupPermission;
  }

  createEvents() {
    return [
      new CustomEvent('editview', {
        detail: {
          url: `/apex/MyAccountsViewManagementVod?retURL=${document.location.href}`,
        },
      }),
    ];
  }
}