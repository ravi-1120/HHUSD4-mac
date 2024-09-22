import MyAccountsAccountNameColumn from './model/myAccountsAccountNameColumn';
import MyAccountsBooleanColumn from './model/myAccountsBooleanColumn';
import MyAccountsChildAccountLinkColumn from './model/myAccountsChildAccountLinkColumn';
import MyAccountsColumn from './model/myAccountsColumn';
import MyAccountsDateColumn from './model/myAccountsDateColumn';
import MyAccountsEmailColumn from './model/myAccountsEmailColumn';
import MyAccountsNumberColumn from './model/myAccountsNumberColumn';
import MyAccountsOrderedMultiPicklistColumn from './model/myAccountsOrderedMultiPicklistColumn';
import MyAccountsPhoneNumberColumn from './model/myAccountsPhoneNumberColumn';
import MyAccountsReferenceColumn from './model/myAccountsReferenceColumn';
import MyAccountsUrlColumn from './model/myAccountsUrlColumn';

export default class MyAccountsColumnFactory {
  static COLUMN_CLASS = {
    double: MyAccountsNumberColumn,
    percent: MyAccountsNumberColumn,
    integer: MyAccountsNumberColumn,
    currency: MyAccountsNumberColumn,
    boolean: MyAccountsBooleanColumn,
    date: MyAccountsDateColumn,
    datetime: MyAccountsDateColumn,
    email: MyAccountsEmailColumn,
    reference: MyAccountsReferenceColumn,
    url: MyAccountsUrlColumn,
  };

  static create(column, viewDefinition, userInformation, labels) {
    if (
      column.objectName?.toLowerCase() === 'account' &&
      (column.name?.toLowerCase() === 'name' || column.name?.toLowerCase() === 'formatted_name_vod__c')
    ) {
      return new MyAccountsAccountNameColumn(column, labels);
    }

    if (column.objectName?.toLowerCase() === 'child_account_vod__c' && column.name?.toLowerCase() === 'parent_child_name_vod__c') {
      return new MyAccountsChildAccountLinkColumn(column, labels);
    }

    const lowercaseFieldType = column.fieldType?.toLowerCase();
    if ('multipicklist' === lowercaseFieldType && column.picklistValues) {
      return new MyAccountsOrderedMultiPicklistColumn(column);
    }

    if ('phone' === lowercaseFieldType && viewDefinition?.source !== 'LOCATION' && userInformation?.CallCenterId) {
      return new MyAccountsPhoneNumberColumn(column, labels);
    }

    const ColumnClass = this.COLUMN_CLASS[lowercaseFieldType] ?? MyAccountsColumn;
    return new ColumnClass(column, labels);
  }
}