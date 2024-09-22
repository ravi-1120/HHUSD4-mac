export default class UniqueFieldName {
  /**
   * Creates a unique field name given a VeevaMyAccountsFieldDefn.
   *
   * @param apexFieldDefinition a VeevaMyAccountsFieldDefn
   * @returns {String} returns a '-' separated string of properties
   */
  static create(apexFieldDefinition) {
    const qualifiers = apexFieldDefinition.qualifiers ?? [];
    const uniqueFieldParts = [apexFieldDefinition.accountRelationship, apexFieldDefinition.objectName, ...qualifiers, apexFieldDefinition.name];
    return uniqueFieldParts.filter(fieldPart => fieldPart).join('-');
  }
}