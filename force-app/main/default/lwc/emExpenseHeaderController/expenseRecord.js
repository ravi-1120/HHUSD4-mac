import VeevaConstant from 'c/veevaConstant';
import VeevaRecord from 'c/veevaRecord';


export default class ExpenseRecord extends VeevaRecord {
  getUpdatableValues(objectInfo) {
    const values = {
      Id: this.id,
      type: this.apiName,
    };
    // resave all fields
    Object.entries(this.fields).forEach(([key, value]) => {
      const field = objectInfo.getFieldInfo(key);
      if (field?.updateable && (field.custom || VeevaConstant.STANDARD_FIELDS_TO_UPDATE.includes(key))) {
        values[key] = value.value;
      }
    });
    return values;
  }
}