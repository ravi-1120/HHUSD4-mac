import MyAccountsColumn from './myAccountsColumn';

export default class MyAccountsChildAccountLinkColumn extends MyAccountsColumn {
  renderer({ value, record, grid }) {
    const hyperlink = document.createElement('a');
    const recId = record['Child_Account_vod__c-Id'];

    hyperlink.textContent = value;
    hyperlink.href = `${window.location.origin}/${recId}`;
    hyperlink.addEventListener('click', (event) => {
      // When the hyperlink is clicked we will will trigger a "rowaction" on the grid
      // Triggering a "rowaction" on the grid will ensure that VeevaBryntumGrid will propagate this as a CustomEvent
      grid.trigger('rowaction', {
        bubbles: true,
        row: { id: record['Child_Account_vod__c-Id'], objectApiName: 'Child_Account_vod__c' },
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