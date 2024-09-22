import VIEW_OBJECT from '@salesforce/schema/View_vod__c';

import MyAccountsButtonController from '../myAccountsButtonController';

export default class CreateNewViewController extends MyAccountsButtonController {
  static REQUIRED_OBJECTS = [VIEW_OBJECT.objectApiName];
  static MESSAGE_REQUEST = MyAccountsButtonController.createMessageRequest().addRequest(
    'CREATE_NEW_VIEW',
    'View',
    'Create New View',
    'createNewViewLabel'
  );

  getLabel(messageMap) {
    return messageMap.createNewViewLabel;
  }

  isVisible(objectInfoMap) {
    return objectInfoMap[VIEW_OBJECT.objectApiName]?.createable;
  }

  createEvents() {
    return [
      new CustomEvent('createnewview', {
        detail: {
          url: `/apex/MyAccountsViewManagementVod?retURL=${document.location.href}`,
        },
      }),
    ];
  }
}