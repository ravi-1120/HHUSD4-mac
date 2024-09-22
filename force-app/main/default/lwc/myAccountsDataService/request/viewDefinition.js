import CriteriaDefinition from './criteriaDefinition';
import LocationIdFieldsStrategy from './locationIdFieldsStrategy';
import ViewBaseDefinition from './viewBaseDefinition';

export default class ViewDefinition extends ViewBaseDefinition {
  constructor(viewDefinitionFromApex) {
    super(viewDefinitionFromApex);
    this.isPublic = viewDefinitionFromApex.isPublic;
    this.owners = viewDefinitionFromApex.owners;
    this.source = viewDefinitionFromApex.source;
    this.baseQuery = this.source === 'LOCATION' ? undefined : viewDefinitionFromApex.baseQuery;
    this.addresses = viewDefinitionFromApex.addresses;
    this.criteria = this.getCriteria(viewDefinitionFromApex.criteria ?? []);
  }

  getCriteria(criteriaArray) {
    return criteriaArray.map(criteria => new CriteriaDefinition(criteria));
  }

  _getIdFieldsStrategy(viewDefinitionFromApex) {
    if (viewDefinitionFromApex.source === 'LOCATION') {
      return new LocationIdFieldsStrategy();
    }

    return super._getIdFieldsStrategy();
  }
}