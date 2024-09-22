import  UniqueFieldName from '../model/uniqueFieldName';
import FieldDefinition from './fieldDefinition';
import IdFieldsStrategy from './idFieldsStrategy';

export default class LocationIdFieldsStrategy extends IdFieldsStrategy {
  create(/* existingColumns */) {
    const childAccountIdFieldDefn = {
      name: 'Id',
      objectName: 'Child_Account_vod__c',
      fieldType: 'id'
    };
    const childAccountChildId = {
      name: 'Id',
      objectName: 'Account',
      fieldType: 'id',
      accountRelationship: 'Child_Account_vod__r'
    };
    const childAccountParentId = {
      name: 'Id',
      objectName: 'Account',
      fieldType: 'id',
      accountRelationship: 'Parent_Account_vod__r'
    };
    return [
      {
        title: UniqueFieldName.create(childAccountIdFieldDefn),
        field: new FieldDefinition(childAccountIdFieldDefn),
      },
      {
        title: UniqueFieldName.create(childAccountChildId),
        field: new FieldDefinition(childAccountChildId),
      },
      {
        title: UniqueFieldName.create(childAccountParentId),
        field: new FieldDefinition(childAccountParentId),
      },
    ];
  }
}