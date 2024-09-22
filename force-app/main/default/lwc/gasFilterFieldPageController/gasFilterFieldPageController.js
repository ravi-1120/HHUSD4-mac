import GasRecordTypeLookupController from 'c/gasRecordTypeLookupController';
import VeevaPageController from 'c/veevaPageController';
import VeevaObjectInfo from 'c/veevaObjectInfo';

// We need to convert MultiPicklist to Picklist because our VeevaField component used by GasFilterField
// uses a dual-listbox for MultiPicklist's where we want our MultiPicklist to show up the same way as a Picklist
const FIELD_TYPE_CONVERSION_MAP = {
  MultiPicklist: 'Picklist',
};

export default class GasFilterFieldPageController extends VeevaPageController {
  constructor(dataSvc, userInterfaceApi, messageSvc, metaStore, objectInfo, record) {
    super(dataSvc, userInterfaceApi, messageSvc, metaStore);
    this.record = record;
    this.page = {
      requests: [],
    };
    this.objectInfo = new VeevaObjectInfo(convertToGasFilterFieldCompatible(objectInfo));
  }

  /**
   * Creates a FieldController based on the field.
   *
   * @override Overrides VeevaPageController
   * @param meta contains the fieldName, label, and whether the field is editable
   * @param record VeevaRecord that will contain the values for each field
   * @returns returns an instance of FieldController for the specific field
   */
  initItemController(meta, record) {
    const { field } = meta;
    let ctrl;
    if ('RecordTypeId' === field) {
      const fieldInfo = this.objectInfo.getFieldInfo(field);
      ctrl = new GasRecordTypeLookupController(meta, this, fieldInfo, record);
    } else {
      meta.noDefaultSelected = true;
      ctrl = super.initItemController(meta, record);
    }
    return ctrl;
  }
}

function convertToGasFilterFieldCompatible(objectInfo) {
  const convertedObjectInfo = {
    ...objectInfo,
    fields: {},
  };

  Object.entries(objectInfo.fields).forEach(([fieldApiName, fieldInfo]) => {
    const convertTo = FIELD_TYPE_CONVERSION_MAP[fieldInfo.dataType];
    const dataType = convertTo ?? fieldInfo.dataType;
    const controllerName = (dataType === 'Picklist') ? null : fieldInfo.controllerName;
    convertedObjectInfo.fields[fieldApiName] = {
      ...fieldInfo,
      dataType,
      controllerName,
    };
  });
  return convertedObjectInfo;
}