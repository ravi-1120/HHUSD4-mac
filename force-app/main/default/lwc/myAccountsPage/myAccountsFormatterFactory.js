import MyAccountsFormatter from './formatters/myAccountsFormatter';
import MyAccountsNumberFormatter from './formatters/myAccountsNumberFormatter';
import MyAccountsURLFormatter from './formatters/myAccountsURLFormatter';

import MyAccountsAccountNameFormatter from './formatters/myAccountsAccountNameFormatter';
import MyAccountsEmailFormatter from './formatters/myAccountsEmailFormatter';
import MyAccountsExcelURLFormatter from './formatters/myAccountsExcelURLFormatter';
import MyAccountsReferenceFormatter from './formatters/myAccountsReferenceFormatter';
import MyAccountsParentChildNameFormatter from './formatters/myAccountsParentChildNameFormatter';

export default class MyAccountsFormatterFactory {
  static FORMATTER_CLASS = {
    double: MyAccountsNumberFormatter,
    integer: MyAccountsNumberFormatter,
    percent: MyAccountsNumberFormatter,
    currency: MyAccountsNumberFormatter,
    url: MyAccountsURLFormatter,
  };

  static EXCEL_FORMATTER_CLASSES = {
    ...MyAccountsFormatterFactory.FORMATTER_CLASS,
    email: MyAccountsEmailFormatter,
    reference: MyAccountsReferenceFormatter,
    url: MyAccountsExcelURLFormatter,
  };

  static create(columnInfo, exportType) {
    const FormatterClass = this._getFormatterClass(columnInfo, exportType) ?? MyAccountsFormatter;
    return new FormatterClass(columnInfo);
  }

  static _getFormatterClass(columnInfo, exportType) {
    let FormatterClass;
    if (exportType === 'excel') {
      if (
        columnInfo.objectName?.toLowerCase() === 'account' &&
        (columnInfo.originalFieldName?.toLowerCase() === 'name' || columnInfo.originalFieldName?.toLowerCase() === 'formatted_name_vod__c')
      ) {
        return MyAccountsAccountNameFormatter;
      }
      if (
        columnInfo.objectName?.toLowerCase() === 'child_account_vod__c' &&
        columnInfo.originalFieldName?.toLowerCase() === 'parent_child_name_vod__c'
      ) {
        return MyAccountsParentChildNameFormatter;
      }
      FormatterClass = MyAccountsFormatterFactory.EXCEL_FORMATTER_CLASSES[columnInfo.sfDisplayType?.toLowerCase()];
    } else {
      FormatterClass = MyAccountsFormatterFactory.FORMATTER_CLASS[columnInfo.sfDisplayType?.toLowerCase()];
    }
    return FormatterClass;
  }
}