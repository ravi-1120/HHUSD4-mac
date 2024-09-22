import { VeevaMessageRequest } from 'c/veevaMessageService';

export default class MyAccountsButtonController {
  static REQUIRED_OBJECTS = [];
  static MESSAGE_REQUEST = MyAccountsButtonController.createMessageRequest();

  constructor(objectInfoMap, messageMap, settings, navItems) {
    this.label = this.getLabel(messageMap);
    this.visible = this.isVisible(objectInfoMap, settings, navItems, messageMap);
    this.selectedAccounts = [];
  }

  get disabled() {
    // can be overridden by child classes for special disable logic
    return false;
  }

  getLabel(/* messageMap */) {
    // to be implemented by child classes
    return null;
  }

  isVisible(/* objectInfoMap, settings, navItems */) {
    // to be implemented by child classes
    return null;
  }

  setSelectedAccounts(selectedAccounts) {
    this.selectedAccounts = selectedAccounts;
  }

  createEvents() {
    // to be implemented by child classes
  }

  createActionEvents() {
    // to be implemented by child classes
  }

  static createMessageRequest() {
    return new VeevaMessageRequest();
  }
}