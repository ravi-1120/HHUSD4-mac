import MyAccountsColumn from './myAccountsColumn';

export default class MyAccountsAccountNameColumn extends MyAccountsColumn {
  constructor(column, labels) {
    super(column, labels);
    this.accountRelationship = column.accountRelationship;
  }

  renderer({ value, record, grid, column }) {
    const hyperlink = document.createElement('a');
    const accountIdField = [column.originalData.accountRelationship, 'Account', 'Id'].filter(field => field).join('-');
    const recId = record[accountIdField];

    hyperlink.textContent = value;
    hyperlink.href = `${window.location.origin}/${recId}`;
    hyperlink.addEventListener('click', (event) => {
      // "this" when the renderer method is called will have a Bryntum Column context
      // (meaning that we do not have access to this class or MyAccountsColumns via "this")

      // When the hyperlink is clicked we will will trigger a "rowaction" on the grid
      // Triggering a "rowaction" on the grid will ensure that VeevaBryntumGrid will propagate this as a CustomEvent
      grid.trigger('rowaction', {
        bubbles: true,
        row: { id: record[accountIdField], objectApiName: 'Account' },
        action: {
          name: 'viewRecord',
        },
      });
      event.preventDefault();
    });
    return {
      tagName: 'div',
      children: [hyperlink],
    };
  }
}