import { LightningElement, api, track } from 'lwc';
import VeevaErrorHandlerMixin from 'c/veevaErrorHandlerMixin';
import DISTANCE_UNIT_TYPE from '@salesforce/schema/EM_Event_Speaker_vod__c.Distance_Unit_Type_vod__c';

export default class TravelDistanceWithUnitTypeField extends VeevaErrorHandlerMixin(LightningElement) {
  @api recordUpdateFlag;
  @api showUndo;
  @api inputAddon;

  currentElementSelector = `c-travel-distance-with-unit-type-field`;
  validityElementsSelector = '[data-validity]';

  @api get ctrl() {
    return this._ctrl;
  }

  set ctrl(value) {
    this._ctrl = value;
  }

  @track _ctrl;

  async connectedCallback() {
    this.inputAddon = this.ctrl.pageCtrl.record.value(DISTANCE_UNIT_TYPE.fieldApiName).displayValue;
    this._ctrl.pageCtrl.track(DISTANCE_UNIT_TYPE.fieldApiName, this, 'updateUnitType');
  }

  handleFieldChange() {
    const fieldChangeEvent = new CustomEvent('fieldchange');
    this.dispatchEvent(fieldChangeEvent);
  }

  updateUnitType(value) {
    this.inputAddon = this._ctrl.pageCtrl.distanceUnitTypeLabels[value];
  }

}