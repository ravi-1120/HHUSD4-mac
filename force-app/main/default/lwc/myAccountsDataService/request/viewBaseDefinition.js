import UniqueFieldName from '../model/uniqueFieldName';
import AccountIdFieldsStrategy from './accountIdFieldsStrategy';
import FieldDefinition from './fieldDefinition';

export default class ViewBaseDefinition {
  constructor(definitionFromApex) {
    this.id = definitionFromApex.id;
    this.name = definitionFromApex.name;
    this.columns = this.getColumns(definitionFromApex);
  }

  getColumns(definitionFromApex) {
    const columnsArray = definitionFromApex.columns ?? [];
    const columnsRequest = columnsArray.map(column => ({
      title: this._getTitle(column),
      field: new FieldDefinition(column),
    }));

    columnsRequest.push(...this._getIdFieldsStrategy(definitionFromApex).create(columnsRequest));

    columnsRequest.push(...this._getReferenceNameFields(columnsArray));

    return columnsRequest;
  }

  _getIdFieldsStrategy(/* definitionFromApex */) {
    return new AccountIdFieldsStrategy();
  }

  _getTitle(column) {
    return this._getTitleFor(column, column.name);
  }

  _getTitleFor(column, fieldName) {
    return UniqueFieldName.create({...column, name: fieldName });
  }

  _getReferenceNameFields(columns) {
    return columns
      .filter(column => column.referenceNameField)
      .map(column => ({
        title: this._getTitleFor(column, column.referenceNameField.replace('.', '-')),
        field: new FieldDefinition({
          ...column,
          fieldType: 'string',
          name: column.referenceNameField,
        }),
      }));
  }
}