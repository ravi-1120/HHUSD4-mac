import VeevaUtils from 'c/veevaUtils';

export default class BaseWarningHandler {
  constructor(warnings, messages) {
    this.warnings = warnings;
    this.messages = messages;
  }

  get recordsToDisplay() {
    return this.warnings;
  }
  
    get idField() {
      return 'Id';
    }

  get nameField() {
    return null;
  }

  get showCheckbox() {
    return true;
  }

  getCheckboxRows() {
    const checkboxRows = this.recordsToDisplay.map(record => this.generateCheckboxRows(record));
    return checkboxRows.flat();
  }

  getCommentRows() {
    return this.warnings.map(record => this.generateCommentRow(record));
  }

  generateCheckboxRows(record) {
    const rows = [];
    record.warnings.forEach((warning, i) => {
      rows.push({
        checked: false,
        id: record[this.idField],
        key: `${record[this.idField]}_${warning.ruleId}`,
        name: i === 0 ? record[this.nameField] : '',
        warning: warning.warningText,
      });
    });
    return rows;
  }

  generateCommentRow(record) {
    const override = JSON.parse(JSON.stringify(record.EM_Event_Override_vod__c));
    override.Id = override.Id ?? VeevaUtils.getRandomId();
    return {
      commentBox: false,
      commentRequired: false,
      id: null,
      name: '',
      override,
    };
  }
}