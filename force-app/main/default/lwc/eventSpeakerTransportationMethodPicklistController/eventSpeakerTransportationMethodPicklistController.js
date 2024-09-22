import PicklistController from 'c/picklistController';
import eventSpeakerTransportationMethodPicklist from './eventSpeakerTransportationMethodPicklist.html';

export default class EventSpeakerTransportationMethodPicklistController extends PicklistController {

  initTemplate() {
    this.template = eventSpeakerTransportationMethodPicklist;
    return super.initTemplate();
  }

  get picklists() {
    if (!this._picklists) {
      return this.options().then(options => {
        this._picklists = this.getDependentOptions(options);
        return this._picklists;
      });
    }
    return this._picklists;
  }

  set picklists(value) {
    this._picklists = value;
  }

  get selected() {
    return this.rawValue;
  }

  set selected(value) {
    this.setFieldValue(value);
  }

  track(element, funcName) {
    this.pageCtrl.track('Speaker_Travel_Distance_vod__c', element, funcName);
  }

  getDependentOptions(options) {
    return options.values.filter(o => {
      const travelDistance = this.record.rawValue('Speaker_Travel_Distance_vod__c');
      const minTravelDistance = o.validFor.Minimum_Travel_Distance_vod__c ? parseInt(o.validFor.Minimum_Travel_Distance_vod__c, 10) : Number.MIN_VALUE;
      const maxTravelDistance = o.validFor.Maximum_Travel_Distance_vod__c ? parseInt(o.validFor.Maximum_Travel_Distance_vod__c, 10) : Number.MAX_VALUE;
      return travelDistance >= minTravelDistance && travelDistance <= maxTravelDistance;
    });
  }

}