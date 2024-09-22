import LookupDataReferenceController from 'c/lookupDataReferenceController';
import TOPIC_NAME from '@salesforce/schema/EM_Catalog_vod__c.Name_vod__c';

export default class TopicReferenceController extends LookupDataReferenceController {
  toSearchRecord(record) {
    const result = super.toSearchRecord(record);
    result.name = result.Name_vod__c || result.name;
    return result;
  }

  get nameField() {
    return TOPIC_NAME.fieldApiName;
  }
}