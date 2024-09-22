import LookupDataReferenceController from 'c/lookupDataReferenceController';

export default class MaterialLookupController extends LookupDataReferenceController {
  toSearchRecord(record) {
    const result = super.toSearchRecord(record);
    result.name = result.Name_vod__c || result.name;
    return result;
  }
}