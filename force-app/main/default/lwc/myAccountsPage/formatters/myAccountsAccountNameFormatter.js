import { UniqueFieldName } from 'c/myAccountsDataService';

import MyAccountsFormatter from './myAccountsFormatter';

export default class MyAccountsAccountNameFormatter extends MyAccountsFormatter {
  constructor(columnInfo) {
    super(columnInfo);
    this.accountRelationship = columnInfo?.accountRelationship;
  }

  format(value, record) {
    if (value == null) {
      return '';
    }

    const currentOrigin = document.location.origin;

    const link = `${currentOrigin}/${
      record[
        UniqueFieldName.create({
          objectName: 'Account',
          name: 'Id',
          accountRelationship: this.accountRelationship,
        })
      ]
    }`;
    const label = value.replace(/"/g, '');
    // Follows SheetJS Cell Object documentation:
    // https://docs.sheetjs.com/docs/csf/cell
    return {
      f: `HYPERLINK("${link}", "${label}")`,
    };
  }
}