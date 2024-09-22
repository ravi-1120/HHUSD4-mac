import MyAccountsColumn from './myAccountsColumn';

export default class myAccountsPhoneNumberColumn extends MyAccountsColumn {
  renderer({ value, record, grid }) {
    if (!value) {
      return null;
    }

    const hyperlink = document.createElement('a');
    hyperlink.textContent = value;
    hyperlink.addEventListener('click', () => {
      // When the hyperlink is clicked we will will trigger a "rowaction" on the grid
      // Triggering a "rowaction" on the grid will ensure that VeevaBryntumGrid will propagate this as a CustomEvent
      grid.trigger('rowaction', {
        bubbles: true,
        row: {
          phoneNumber: value,
          record,
        },
        action: {
          name: 'call',
        },
      });
    });
    return {
      tagName: 'div',
      children: [hyperlink],
    };
  }
}