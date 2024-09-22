import VeevaSectionController from 'c/veevaSectionController';
import { getPageController } from 'c/veevaPageControllerFactory';

import EVENT from '@salesforce/schema/Expense_Header_vod__c.Event_vod__c';
import EXPENSE_LINE from '@salesforce/schema/Expense_Line_vod__c';

import template from './emSplitExpenseLineSectionController.html';

export default class EmSplitExpenseLineSectionController extends VeevaSectionController {
  initTemplate() {
    this.template = template;
    return this;
  }

  async getExpenseLinePageCtrl(page) {
    const [splitExpenseLine] = await this.pageCtrl.getExpenseLines();
    const { record: expenseLineRecord } = splitExpenseLine;
    expenseLineRecord.fields[EVENT.fieldApiName] = this.pageCtrl.record.value(EVENT.fieldApiName);

    const expenseLineCtrl = getPageController(EXPENSE_LINE.objectApiName);
    expenseLineCtrl.objectInfo = this.pageCtrl.expenseLineInfo;
    page.action = this.pageCtrl.page.action;
    expenseLineCtrl.record = expenseLineRecord;
    expenseLineCtrl.page = page;
    expenseLineCtrl.expenseHeaderPleParams = await this.pageCtrl.getPleParams();
    expenseLineCtrl.isSplitExpense = true;

    splitExpenseLine.pageCtrl = expenseLineCtrl;

    return expenseLineCtrl;
  }
}