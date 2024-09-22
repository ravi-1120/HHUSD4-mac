import MyAccountsColumn from './myAccountsColumn';

export default class MyAccountsUrlColumn extends MyAccountsColumn {
  renderer({ value }) {
    if (!value) {
      return null;
    }

    let url;
    if (value.startsWith('http://') || value.startsWith('https://')) {
      url = value;
    } else {
      url = `http://${value}`;
    }

    const hyperlink = document.createElement('a');
    hyperlink.textContent = url;
    hyperlink.href = url;
    hyperlink.target = '_blank';
    return {
      tagName: 'div',
      children: [hyperlink],
    };
  }
}