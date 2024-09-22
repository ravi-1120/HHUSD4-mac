import MyAccountsColumn from './myAccountsColumn';

export default class MyAccountsEmailColumn extends MyAccountsColumn {
  renderer({ value }) {
    if (!value) {
      return null;
    }

    const hyperlink = document.createElement('a');
    hyperlink.textContent = value;
    hyperlink.href = `mailto:${value}`;
    return {
      tagName: 'div',
      children: [hyperlink],
    };
  }
}