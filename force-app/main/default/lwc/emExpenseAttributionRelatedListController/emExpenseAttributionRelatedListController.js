import VeevaRelatedListController from 'c/veevaRelatedListController';
import EmExpenseConstant from 'c/emExpenseConstant';
import {
  isStatusSendingOrSubmitted,
  addConcurStatusToQueryFields,
  hideDropdownButtons,
  handleNoButtonDropdown,
} from 'c/emSubmitToConcurErrorHandling';

export default class EmExpenseAttributionRelatedListController extends VeevaRelatedListController {
  getQueryFields(columns) {
    const queryFields = super.getQueryFields(columns);
    return addConcurStatusToQueryFields(queryFields, `Expense_Line_vod__r.Expense_Header_vod__r.${EmExpenseConstant.CONCUR_STATUS}`);
  }

  async getRowActions(row, doneCallback) {
    const expenseHeader = row?.Expense_Line_vod__r.Expense_Header_vod__r;
    if (await hideDropdownButtons(row, expenseHeader?.Id, expenseHeader?.[EmExpenseConstant.CONCUR_STATUS], this.pageCtrl)) {
      handleNoButtonDropdown(row, doneCallback, this.pageCtrl);
    } else {
      await super.getRowActions(row, doneCallback);
    }
  }

  async getButtons() {
    let buttons = super.getButtons();
    if (await isStatusSendingOrSubmitted(this.pageCtrl.concurSvc, this.pageCtrl?.record?.fields?.Expense_Header_vod__c?.value)) {
      buttons = [];
    }
    return buttons;
  }
}