import BaseWarningHandler from './baseWarningHandler';

export default class ExpenseWarningHandler extends BaseWarningHandler {
  get header() {
    return this.messages.POTENTIAL_EXPENSE_WARNING_TITLE;
  }

  get subheader() {
    return this.messages.POTENTIAL_EXPENSE_WARNING_SUBTITLE;
  }

  get showCheckbox() {
    return false;
  }
}