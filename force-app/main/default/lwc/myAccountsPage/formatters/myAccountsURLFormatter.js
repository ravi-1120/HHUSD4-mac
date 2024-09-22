import MyAccountsFormatter from './myAccountsFormatter';

export default class MyAccountsURLFormatter extends MyAccountsFormatter {
  format(value) {
    if (value == null) {
      return super.format(value);
    }

    let url;
    if (value.startsWith('http://') || value.startsWith('https://')) {
      url = value;
    } else {
      url = `http://${value}`;
    }
    return url;
  }
}