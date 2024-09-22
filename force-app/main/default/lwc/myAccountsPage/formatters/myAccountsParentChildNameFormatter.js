import { UniqueFieldName } from 'c/myAccountsDataService';

import MyAccountsFormatter from "./myAccountsFormatter";

export default class MyAccountsParentChildNameFormatter extends MyAccountsFormatter {
  format(value, record) {
    if (value == null) {
      return '';
    }

    const currentOrigin = document.location.origin;

    const link = `${currentOrigin}/${
      record[
        UniqueFieldName.create({
          objectName: 'Child_Account_vod__c',
          name: 'Id',
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