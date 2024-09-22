export default class ExpenseLineDataSvc {
  constructor(dataSvc) {
    this.dataSvc = dataSvc;
  }

  delete(id) {
    const path = `/api/v1/layout3/data/Expense_Line_vod__c/${id}`;
    return this.dataSvc.sendRequest('DELETE', path, null, null, 'deleteExpenseLine');
  }
}