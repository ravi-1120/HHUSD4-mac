import FieldDefinition from './fieldDefinition';

export default class CriteriaDefinition {
  constructor(criteria) {
    this.field = new FieldDefinition(criteria.field);
    this.operator = criteria.operator;
    this.value = criteria.value;
  }
}