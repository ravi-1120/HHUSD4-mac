import VeevaRecord from 'c/veevaRecord';
import EmEventConstant from 'c/emEventConstant';

export default class EmEventRecord extends VeevaRecord {
  updateReferenceField(field, reference) {
    if (field?.apiName === EmEventConstant.COUNTRY && reference) {
      this.updateCountryNameLabel(reference.name);
    } else {
      super.updateReferenceField(field, reference);
    }
  }

  updateCountryNameLabel(displayValue) {
    if (this.fields[EmEventConstant.COUNTRY_LOOKUP]) {
      this.fields[EmEventConstant.COUNTRY_LOOKUP].displayValue = displayValue;
    } else {
      this.fields[EmEventConstant.COUNTRY_LOOKUP] = {
        displayValue,
        value: null,
      };
    }
  }

  reference(field) {
    if (field && field.apiName === EmEventConstant.COUNTRY) {
      const ref = {
        name: this.displayValue(EmEventConstant.COUNTRY_LOOKUP),
        id: this.rawValue(EmEventConstant.COUNTRY),
        apiName: EmEventConstant.COUNTRY,
      };
      return ref;
    }
    return super.reference(field);
  }
}