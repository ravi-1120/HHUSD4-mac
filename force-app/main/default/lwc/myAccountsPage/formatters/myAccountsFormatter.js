export default class MyAccountsFormatter {
  /**
   * @param columnInfo provides additional information related to the current column
   */
  // eslint-disable-next-line no-useless-constructor, no-empty-function
  constructor(/* columnInfo */) {}

  /**
   * Format the given value.
   *
   * @param value value to display and format
   * @param record record with additional information
   * @returns
   */
  // eslint-disable-next-line no-unused-vars
  format(value, record) {
    return value ?? '';
  }
}