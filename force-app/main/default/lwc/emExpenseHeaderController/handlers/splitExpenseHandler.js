export default class SplitExpenseHandler {
  constructor(pageCtrl) {
    this.pageCtrl = pageCtrl;
  }

  async processLayout(layout) {
    if (this.pageCtrl.expenseLineInfo) {
      const lines = await this.pageCtrl.getExpenseLines();
      if (!lines.length) {
        await this.pageCtrl.createNewExpenseLine();
      }
      layout.sections.push({
        heading: this.pageCtrl.expenseLineInfo.label,
        rawHeading: this.pageCtrl.expenseLineInfo.label,
        splitExpenseLineSection: true,
        key: `${layout.sections.length}`,
        layoutRows: [],
      });
      if (this.pageCtrl.expenseAttrInfo) {
        const participantsLabel = await this.pageCtrl.getMessageWithDefault('PARTICIPANTS', 'EVENT_MANAGEMENT', 'Participants');
        layout.sections.push({
          heading: participantsLabel,
          rawHeading: participantsLabel,
          participantsSection: true,
          key: `${layout.sections.length}`,
          layoutRows: [],
        });
      }
    }
  }

  processError(data) {
    if (data.Expense_Lines_vod__r) {
      data.Expense_Lines_vod__r.forEach((line, index) => {
        const expenseLineRecordId = this.pageCtrl.expenseLines[index].id;
        if (line.fieldErrors) {
          const fieldErrors = { ...line.fieldErrors };
          this.pageCtrl.fieldErrors = this.pageCtrl.fieldErrors ?? {};
          this.pageCtrl.fieldErrors[expenseLineRecordId] = fieldErrors;
          this.pageCtrl.expenseLines[index].pageCtrl.fieldErrors = { [expenseLineRecordId]: fieldErrors };
        }
        const attributions = line.Expense_Attributions_vod__r;
        if (attributions?.length) {
          attributions.forEach(attribution => {
            if (attribution.fieldErrors && Object.keys(attribution.fieldErrors).length) {
              Object.values(attribution.fieldErrors).forEach(error => this.pageCtrl.addRecordError(error));
            }
          });
        }
      });
    }
  }
}