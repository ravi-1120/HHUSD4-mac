export default class PaymentHandler {
  constructor(pageCtrl) {
    this.pageCtrl = pageCtrl;
  }

  async processLayout(layout) {
    if (
      layout.relatedLists?.find(rl => rl.relationship === 'Expense_Lines_vod__r') &&
      this.pageCtrl.expenseLineInfo?.labelPlural &&
      this.pageCtrl.expenseLineInfo.fields &&
      (this.pageCtrl.action !== 'View' || (await this.pageCtrl.getExpenseLines()).length)
    ) {
      layout.sections.push({
        heading: this.pageCtrl.expenseLineInfo.labelPlural,
        rawHeading: this.pageCtrl.expenseLineInfo.labelPlural,
        expenseLineInfo: this.pageCtrl.expenseLineInfo,
        expenseLineSection: true,
        key: `${layout.sections.length}`,
        layoutRows: [],
      });
    }
  }

  processError(data) {
    if (data.Expense_Lines_vod__r) {
      data.Expense_Lines_vod__r.forEach((line, index) => {
        const expenseLineRecordId = this.pageCtrl.expenseLines[index].id;
        this.pageCtrl.expenseLines[index].pageCtrl.fieldErrors = this.pageCtrl.expenseLines[index].pageCtrl.fieldErrors || {};
        this.pageCtrl.expenseLines[index].pageCtrl.fieldErrors[expenseLineRecordId] = { ...line.fieldErrors };
        const recordErrors = [...line.recordErrors];
        const attributions = line.Expense_Attributions_vod__r;
        if (attributions?.length) {
          attributions.forEach(attribution => {
            if (attribution.fieldErrors && Object.keys(attribution.fieldErrors).length) {
              recordErrors.push(...Object.values(attribution.fieldErrors));
            }
          });
        }
        this.pageCtrl.expenseLines[index].rowError = recordErrors.join('\n');
      });
    }
  }
}