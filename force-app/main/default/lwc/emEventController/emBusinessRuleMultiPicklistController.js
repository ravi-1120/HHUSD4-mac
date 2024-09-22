import PicklistController from 'c/picklistController';

export default class EmBusinessRulePicklistController extends PicklistController {

  initTemplate() {
    this.multiPicklist = true;
    return this;
  }
}