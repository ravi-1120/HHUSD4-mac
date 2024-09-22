import MyAccountsFormatter from './myAccountsFormatter';

export default class MyAccountsReferenceFormatter extends MyAccountsFormatter {
  constructor(columnInfo) {
    super(columnInfo);
    this.referenceIdField = columnInfo?.referenceIdField;
  }

  format(value, record) {
    if (value == null) {
      return '';
    }
    if (this.referenceIdField == null) {
      return value;
    }
    const referenceIdValue = record[this.referenceIdField] ?? record.originalData?.[this.referenceIdField];
    if (referenceIdValue == null) {
      return value;
    }

    const currentOrigin = document.location.origin;
    const label = value.replace(/"/g, '');
    // Follows SheetJS Cell Object documentation:
    // https://docs.sheetjs.com/docs/csf/cell
    return {
      f: `HYPERLINK("${currentOrigin}/${referenceIdValue}", "${label}")`,
    };
  }
}