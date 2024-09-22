import EmRelatedListController from 'c/emRelatedListController';
import EmConcurService from 'c/emConcurService';
import EmEventConstant from 'c/emEventConstant';
import EmExpenseConstant from 'c/emExpenseConstant';
import { getService, SERVICES } from 'c/veevaServiceFactory';
import { isStatusSendingOrSubmitted, addConcurStatusToQueryFields, handleNoButtonDropdown } from 'c/emSubmitToConcurErrorHandling';

export default class EmExpenseLineRelatedListController extends EmRelatedListController {
  concurSvc = new EmConcurService(getService(SERVICES.DATA), getService(SERVICES.UI_API));

  get isExpenseHeaderParent() {
    return this.pageCtrl.objectApiName === `Expense_Header_vod__c`;
  }

  async launchNewFlow(context) {
    if (!this.isExpenseHeaderParent) {
      const defaultMessage = 'Expense line cannot be created without an expense header. Please create an expense header first.';
      const message = (await this.pageCtrl.getMessageWithDefault('HEADER_REQUIRED_LINES', 'EVENT_MANAGEMENT', defaultMessage)) || defaultMessage;
      throw message;
    } else {
      super.launchNewFlow(context);
    }
  }

  async deleteRow(rowId, objectApiName) {
    if (await isStatusSendingOrSubmitted(this.concurSvc, rowId, objectApiName)) {
      throw await this.pageCtrl.getMessageWithDefault('CONCUR_ALREADY_SENT_VIEW', 'Concur', EmExpenseConstant.CONCUR_ALREADY_SENT_DEFAULT);
    }
    const result = await super.deleteRow(rowId, objectApiName);
    this.pageCtrl.refreshParentRecordUi(!this.isExpenseHeaderParent, this.pageCtrl.id, EmEventConstant.FIELDS_EXPENSE_LINES_UPDATE_ASYNC);
    return result;
  }

  getQueryFields(columns) {
    const queryFields = super.getQueryFields(columns);
    return addConcurStatusToQueryFields(queryFields, `Expense_Header_vod__r.${EmExpenseConstant.CONCUR_STATUS}`);
  }

  async getRowActions(row, doneCallback) {
    const concurStatus = row?.Expense_Header_vod__r?.[EmExpenseConstant.CONCUR_STATUS];
    if (EmExpenseConstant.HIDE_BUTTONS_CONCUR_STATUSES.includes(concurStatus)) {
      handleNoButtonDropdown(row, doneCallback, this.pageCtrl);
    } else {
      await super.getRowActions(row, doneCallback);
    }
  }

  async getButtons() {
    let buttons = await super.getButtons();
    if (this.isExpenseHeaderParent && (await isStatusSendingOrSubmitted(this.pageCtrl.concurSvc, this.pageCtrl?.record?.id))) {
      buttons = [];
    }
    return buttons;
  }
}