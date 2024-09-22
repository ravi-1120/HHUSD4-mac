export default class FieldDefinition {
  constructor(field) {
    this.name = field.name;
    this.object = field.objectName;
    this.qualifiers = field.qualifiers ?? [];
    this.type = field.fieldType;
    this.accountRelationship = field.accountRelationship;
  }
}