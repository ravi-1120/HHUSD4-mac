import MyAccountsButtonController from '../myAccountsButtonController';

export default class MassUpdateActionController extends MyAccountsButtonController {
  static MESSAGE_REQUEST = MyAccountsButtonController.createMessageRequest().addRequest('MASS_UPDATE', 'MyAccounts', 'Mass Update', 'massUpdateBtn');

  getLabel(messageMap) {
    return messageMap.massUpdateBtn;
  }

  isVisible(/* objectInfoMap, settings */) {
    return true;
  }

  get disabled() {
    return false;
  }

  async createActionEvents() {
    return [new CustomEvent('massupdate')];
  }
}