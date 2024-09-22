import EVENT_FORMAT from '@salesforce/schema/EM_Event_vod__c.Event_Format_vod__c';
import LOCATION_TYPE from '@salesforce/schema/EM_Event_vod__c.Location_Type_vod__c';

import EmBusinessRulePicklistController from './emBusinessRuleMultiPicklistController';

export default class MealTypePicklistController extends EmBusinessRulePicklistController {
  get picklists() {
    if (!this._picklists) {
      return this.options().then(options => {
        this._picklists = this.getDependentOptions(options);
        return this._picklists;
      });
    }
    return this._picklists;
  }

  track(element, funcName) {
    this.pageCtrl.track(EVENT_FORMAT.fieldApiName, element, funcName);
    this.pageCtrl.track(LOCATION_TYPE.fieldApiName, element, funcName);
  }

  getDependentOptions(options) {
    const eventFormat = this.record.rawValue(EVENT_FORMAT.fieldApiName) || '';
    const locationType = this.record.rawValue(LOCATION_TYPE.fieldApiName) || '';
    return options.values.filter(option => {
      const eventFormatValid = option.validFor.Event_Format_vod__c.includes(eventFormat);
      const locationTypeValid = option.validFor.Location_Type_vod__c.includes(locationType);
      return eventFormatValid && locationTypeValid;
    });
  }
}