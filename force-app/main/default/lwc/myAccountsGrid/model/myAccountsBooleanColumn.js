import MyAccountsColumn from './myAccountsColumn';

export default class MyAccountsBooleanColumn extends MyAccountsColumn {
  renderer({ value }) {
    return {
      tag: 'i',
      className: {
        'b-fa': true,
        'b-fa-check': value,
      },
    };
  }

  _getBryntumType() {
    // use default Bryntum Type
    return null;
  }
}