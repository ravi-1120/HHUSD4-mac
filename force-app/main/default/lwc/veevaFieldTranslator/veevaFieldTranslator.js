export default class VeevaFieldTranslator {
  /**
   * The purpose of VeevaFieldTranslator is to provide a generic class for mapping field names to field values, and then
   * mapping each of those values to a corresponding Veeva Message.
   *
   * For example, the VeevaBryntumGrid component is capable of dynamically rendering a cell's contents based on the underlying
   * field value(s) passed into the cell. Using an instance of VeevaFieldTranslator, we could dynamically map "enum" fields on
   * a record to a Map of Veeva Messages that are translated to the end-user's locale.
   *
   * @param {Map<String, Map<String, String>>} fieldNameAndValueToMessageMap - A nested Map of Maps. The top-level Map
   * should have keys that correspond to the names of an object's fields. The associated child Maps should themselves be
   * Maps of a field's values to associated Veeva Messages.
   */
  constructor(fieldNameAndValueToMessageMap) {
    this.fieldNameAndValueToMessageMap = fieldNameAndValueToMessageMap ?? new Map();
  }

  /**
   * Assigns a new Map of field values and messages to a specified field name.
   *
   * @param {String} fieldName - Name of new or existing field to add new mapping.
   * @param {Map<String, String>} valueToMessageMap - Map of the field's values to messages.
   */
  addValuesAndMessagesForField(fieldName, valueToMessageMap) {
    this.fieldNameAndValueToMessageMap.set(fieldName, valueToMessageMap);
  }

  /**
   * Assigns a single new message to a particular value of a particular field.
   *
   * @param {String} fieldName - Name of new or existing field to add value to.
   * @param {String} fieldValue - Name of new or existing value to add message to.
   * @param {String} message - Message to associate to #fieldName and #fieldValue.
   */
  addMessageForFieldAndValue(fieldName, fieldValue, message) {
    let mapForField = this.fieldNameAndValueToMessageMap.get(fieldName);
    if (!mapForField) {
      mapForField = new Map();
      this.fieldNameAndValueToMessageMap.set(fieldName, mapForField);
    }
    mapForField.set(fieldValue, message);
  }

  /**
   * Returns the message associated with the supplied #fieldName and #fieldValue.
   *
   * @param {*} fieldName
   * @param {*} fieldValue
   * @returns {String} message found for the given #fieldName and #fieldValue, or undefined if either #fieldName
   * or #fieldValue do not exist.
   */
  getMessageForFieldAndValue(fieldName, fieldValue) {
    return this.fieldNameAndValueToMessageMap.get(fieldName)?.get(fieldValue);
  }
}