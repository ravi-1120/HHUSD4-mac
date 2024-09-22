import LOCALE from '@salesforce/i18n/locale';

export default class VeevaNumberHelper {
  /**
   * Formats incoming number as a percent.
   *
   * @param {Number} number representing the percentage to render. Note that there is a mismatch between Salesforce's representation of a
   * percent and Intl.NumberFormat. For example, Salesforce represents `23%` as `23`, whereas Intl.NumberFormat represents
   * `23%` as `0.23`. This function expects a Salesforce input (e.g. `23`) and thus will divide the input by 100.
   * @returns {String} representing formatted percentage in user's locale.
   */
  static formatPercent(number) {
    return Intl.NumberFormat(LOCALE, { style: 'percent' }).format(number / 100);
  }
}