import EmController from 'c/emController';
import PicklistController from 'c/picklistController';
import EventSpeakerTravelDistanceFieldController from 'c/eventSpeakerTravelDistanceFieldController';
import EventSpeakerTransportationMethodPicklistController from 'c/eventSpeakerTransportationMethodPicklistController';
import SPEAKER_LODGE_TYPE from '@salesforce/schema/EM_Event_Speaker_vod__c.Speaker_Lodging_Type_vod__c';
import SPEAKER_LODGE_NIGHTS from '@salesforce/schema/EM_Event_Speaker_vod__c.Speaker_Lodging_Nights_vod__c';
import SPEAKER_TRANSPORTATION_METHOD from '@salesforce/schema/EM_Event_Speaker_vod__c.Speaker_Transportation_Method_vod__c';
import SPEAKER_TRAVEL_DISTANCE from '@salesforce/schema/EM_Event_Speaker_vod__c.Speaker_Travel_Distance_vod__c';
import DISTANCE_UNIT_TYPE from '@salesforce/schema/EM_Event_Speaker_vod__c.Distance_Unit_Type_vod__c';
import TravelDistanceFieldViewController from './travelDistanceFieldViewController';

export default class EmEventSpeakerController extends EmController {
  distanceUnitTypeLabels = {};

  getHeaderButtons() {
    const buttons = super.getHeaderButtons();
    return buttons.filter(button => this.shouldShowButton(button));
  }

  shouldShowButton(button) {
    let showButton = true;
    if (button.name === 'Link_Contract_vod') {
      const event = this.record.rawValue('Event_vod__r');
      if (event?.fields?.Lock_vod__c?.value) {
        showButton = false;
      }
    }
    return showButton;
  }

  async loadMetadata() {
    await Promise.all([this.initDistanceUnitTypeLabels(), super.loadMetadata()]);
  }

  async initData() {
    await super.initData();
    this.initTravelDistanceDisplayValue();
  }

  async initDistanceUnitTypeLabels() {
    if (this.action === 'View' || !this.objectInfo.getFieldInfo(DISTANCE_UNIT_TYPE.fieldApiName)) {
      return;
    }
    const distanceUnitTypePicklist = await this.getPicklistValues(DISTANCE_UNIT_TYPE.fieldApiName);
    for (let i = 0; i < distanceUnitTypePicklist.values.length; i++) {
      this.distanceUnitTypeLabels[distanceUnitTypePicklist.values[i].value] = distanceUnitTypePicklist.values[i].label;
    }
  }

  initTravelDistanceDisplayValue() {
    if (
      this.page.action === 'View' &&
      this.isFieldOnLayout(SPEAKER_TRAVEL_DISTANCE.fieldApiName) &&
      this.isFieldOnLayout(DISTANCE_UNIT_TYPE.fieldApiName)
    ) {
      const travelDistanceDecimalPlaces = this.objectInfo.getFieldInfo('Speaker_Travel_Distance_vod__c').scale ?? 0;
      const travelDistanceWithUnitType = `${this.record.rawValue(SPEAKER_TRAVEL_DISTANCE.fieldApiName)?.toFixed(travelDistanceDecimalPlaces) ??
        ''} ${this.record.displayValue(DISTANCE_UNIT_TYPE.fieldApiName) ?? ''}`;
      this.record.setDisplayValue(SPEAKER_TRAVEL_DISTANCE.fieldApiName, travelDistanceWithUnitType);
    }
  }

  processLayout(layout) {
    this.picklistOptionMap = layout.picklistOptionMap ?? {};
    return super.processLayout(layout);
  }

  isItemToHide(item) {
    let toHide;
    switch (item.field) {
      case DISTANCE_UNIT_TYPE.fieldApiName:
        toHide = true;
        break;
      case SPEAKER_TRAVEL_DISTANCE.fieldApiName:
      case SPEAKER_TRANSPORTATION_METHOD.fieldApiName:
        toHide = this.shouldHideBusinessRuleField(SPEAKER_TRANSPORTATION_METHOD.fieldApiName);
        break;
      case SPEAKER_LODGE_TYPE.fieldApiName:
      case SPEAKER_LODGE_NIGHTS.fieldApiName:
        toHide = this.shouldHideBusinessRuleField(SPEAKER_LODGE_TYPE.fieldApiName);
        break;
      default:
        toHide = super.isItemToHide(item);
        break;
    }
    return toHide;
  }

  shouldHideBusinessRuleField(fieldApiName) {
    return (
      this.action === 'Edit' &&
      (!this.picklistOptionMap[fieldApiName] || this.picklistOptionMap[fieldApiName]?.values?.length === 0) &&
      !this.record.rawValue(fieldApiName)
    );
  }

  initItemController(meta, record) {
    const { field } = meta;
    if (field) {
      const fieldDescribe = this.objectInfo.getFieldInfo(field);
      if (field === SPEAKER_TRANSPORTATION_METHOD.fieldApiName) {
        return new EventSpeakerTransportationMethodPicklistController(meta, this, fieldDescribe, record);
      }
      if (field === SPEAKER_LODGE_TYPE.fieldApiName) {
        return new PicklistController(meta, this, fieldDescribe, record);
      }
      if (field === SPEAKER_TRAVEL_DISTANCE.fieldApiName) {
        if (this.page.action !== 'View') {
          return new EventSpeakerTravelDistanceFieldController(meta, this, fieldDescribe, record);
        }
        if (
          this.page.action === 'View' &&
          this.isFieldOnLayout(SPEAKER_TRAVEL_DISTANCE.fieldApiName) &&
          this.isFieldOnLayout(DISTANCE_UNIT_TYPE.fieldApiName)
        ) {
          return new TravelDistanceFieldViewController(meta, this, fieldDescribe, record);
        }
      }
    }
    return super.initItemController(meta, record);
  }

  async getPicklistValues(field, recordTypeId) {
    switch (field) {
      case SPEAKER_TRANSPORTATION_METHOD.fieldApiName:
      case SPEAKER_LODGE_TYPE.fieldApiName:
        return this.picklistOptionMap[field] ?? { values: [] };
      default:
        return super.getPicklistValues(field, recordTypeId);
    }
  }

  setFieldValue(field, value, reference, record, source) {
    super.setFieldValue(field, value, reference, record, source);
    if (field.apiName === SPEAKER_TRANSPORTATION_METHOD.fieldApiName && this.picklistOptionMap.Speaker_Transportation_Method_vod__c) {
      const distanceUnitType = this.picklistOptionMap.Speaker_Transportation_Method_vod__c.values?.find(v => value === v.value)?.validFor
        ?.Distance_Unit_Type_vod__c;
      this.setFieldValue(DISTANCE_UNIT_TYPE.fieldApiName, distanceUnitType ?? '');
    }
  }
}