import EmExpenseConstant from 'c/emExpenseConstant';

export default class EmConcurService {
  constructor(dataSvc, uiApi) {
    this.dataSvc = dataSvc;
    this.uiApi = uiApi;
  }

  async getConcurStatus(recordId, objectApiName = EmExpenseConstant.EXPENSE_HEADER) {
    let headerRecord;
    switch (objectApiName) {
      case EmExpenseConstant.EXPENSE_HEADER:
        headerRecord = await this.uiApi.getRecord(recordId, [`${EmExpenseConstant.EXPENSE_HEADER}.${EmExpenseConstant.CONCUR_STATUS}`]);
        break;
      case 'Expense_Line_vod__c': {
        const lineRecord = await this.uiApi.getRecord(recordId, [`Expense_Line_vod__c.Expense_Header_vod__r.${EmExpenseConstant.CONCUR_STATUS}`]);
        headerRecord = lineRecord.fields?.Expense_Header_vod__r?.value;
        break;
      }
      default:
        break;
    }
    return headerRecord?.fields?.[EmExpenseConstant.CONCUR_STATUS]?.value;
  }

  async submitToConcur(expenseHeaderId, checkBusinessRules = false) {
    let body = null;
    if (checkBusinessRules) {
      body = {
        checkExpenseRules: true,
        checkSpeakerRules: true,
        platform: 'Online',
      };
    }
    return this.dataSvc.sendRequest('POST', `/api/v1/layout3/Expense_Header_vod__c/concur/submit/${expenseHeaderId}`, null, body, 'submitToConcur');
  }
}