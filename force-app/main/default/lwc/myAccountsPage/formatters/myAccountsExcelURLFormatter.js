import MyAccountsURLFormatter from './myAccountsURLFormatter';

const DOUBLE_QUOTE_URI_ENCODED = encodeURIComponent('"');
export default class MyAccountsExcelURLFormatter extends MyAccountsURLFormatter {
  format(value) {
    const formattedValue = super.format(value);
    // If formatted value is an empty string we will return the empty string
    if (formattedValue === '') {
      return formattedValue;
    }

    const formattedValueWithEncodedDoubleQuotes = formattedValue.replace(/"/g, DOUBLE_QUOTE_URI_ENCODED);
    const url = this.getURL(value);
    const urlWithEncodedDoubleQuotes = url.replace(/"/g, DOUBLE_QUOTE_URI_ENCODED);
    return {
      f: `HYPERLINK("${urlWithEncodedDoubleQuotes}", "${formattedValueWithEncodedDoubleQuotes}")`,
    };
  }

  getURL(value) {
    try {
      let url;
      if (value.startsWith('http://') || value.startsWith('https://')) {
        url = new URL(value).toString();
      } else {
        url = new URL(`http://${value}`).toString();
      }
      return url;
    } catch (e) {
      return value;
    }
  }
}