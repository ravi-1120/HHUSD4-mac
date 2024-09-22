import MyAccountsFormatter from './myAccountsFormatter';

export default class MyAccountsEmailFormatter extends MyAccountsFormatter {
  format(value) {
    if (value == null) {
      return '';
    }

    // Follows SheetJS Cell Object documentation:
    // https://docs.sheetjs.com/docs/csf/cell
    return {
      f: `HYPERLINK("mailto:${value}", "${value}")`,
    };
  }
}