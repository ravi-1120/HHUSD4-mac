import UniqueFieldName from '../model/uniqueFieldName';
import FieldDefinition from './fieldDefinition';
import IdFieldsStrategy from './idFieldsStrategy';

export default class AccountIdFieldsStrategy extends IdFieldsStrategy {
  create(existingColumns) {
    const idFields = [];

    const hasAccountIdInRequest = existingColumns.find(column => column.field.object === 'Account' && column.field.name === 'Id');
    if (!hasAccountIdInRequest) {
      const accountIdFieldDefn = {
        name: 'Id',
        objectName: 'Account',
        fieldType: 'id',
      };
      idFields.push({
        title: UniqueFieldName.create(accountIdFieldDefn),
        field: new FieldDefinition(accountIdFieldDefn),
      });
    }

    const addressColumns = existingColumns.filter(column => column.field.object === 'Address_vod__c');
    const hasAddressIdInRequest = addressColumns.find(addressColumn => addressColumn.field.name === 'Id');
    if (addressColumns.length > 0 && !hasAddressIdInRequest) {
      const addressIdFieldDefn = {
        name: 'Id',
        objectName: 'Address_vod__c',
        fieldType: 'id'
      };
      idFields.push({
        title: UniqueFieldName.create(addressIdFieldDefn),
        field: new FieldDefinition(addressIdFieldDefn),
      });
    }

    return idFields;
  }
}