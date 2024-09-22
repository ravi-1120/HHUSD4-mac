import LOCALE from '@salesforce/i18n/locale';

import MyAccountsFormatter from './myAccountsFormatter';

export default class MyAccountsNumberFormatter extends MyAccountsFormatter {
  constructor(columnInfo) {
    super(columnInfo);
    this.fraction = columnInfo.scale;
  }

  format(value) {
    if (value == null) {
      return super.format(value);
    }

    return Intl.NumberFormat(LOCALE.replace('_', '-'), {
      maximumFractionDigits: this.fraction,
      minimumFractionDigits: this.fraction,
    }).format(value);
  }
}