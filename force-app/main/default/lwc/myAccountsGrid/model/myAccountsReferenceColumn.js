import MyAccountsColumn from './myAccountsColumn';

export default class MyAccountsReferenceColumn extends MyAccountsColumn {
  constructor(column, labels) {
    super(column, labels);
    // The reference id field will be the "original" field name that MyAccountsColumn determines
    this.referenceIdField = super._getFieldName(column);
    this.referenceToObject = column.referenceToObject;
  }

  renderer({ value, record, grid, column }) {
    if (column.originalData.referenceToObject?.toLowerCase() === 'recordtype') {
      return value;
    }

    const hyperlink = document.createElement('a');
    const recId = record.originalData[column.originalData.referenceIdField];

    hyperlink.textContent = value;
    hyperlink.href = `${window.location.origin}/${recId}`;
    hyperlink.addEventListener('click', (event) => {
      // When the hyperlink is clicked we will will trigger a "rowaction" on the grid
      // Triggering a "rowaction" on the grid will ensure that VeevaBryntumGrid will propagate this as a CustomEvent
      // The row we send will be the reference record id and the objectApiName of the record we are trying to view
      grid.trigger('rowaction', {
        bubbles: true,
        // column.originalData will give us access to this class's properties or MyAccountsColumn's properties
        row: {
          // record.originalData will contain all of the fields that were sent by the response from the back-end
          // we specifically want to get the reference field id this allows us to perform the 'viewRecord' action
          id: record.originalData[column.originalData.referenceIdField],
          objectApiName: column.originalData.referenceToObject,
        },
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

  _getFieldName(column) {
    // The field name for reference fields is the referenceNameField and we replace the '.' with '-'
    // If for some reason the referenceNameField is not defined then we will fallback to the column.name
    // For Example, { object: Account, name: RecordTypeId, referenceNameField: RecordType.Name } -> Account-RecordType-Name
    const referenceField = column.referenceNameField?.replace('.', '-') ?? column.name;
    return super._getFieldName({ ...column, name: referenceField });
  }
}