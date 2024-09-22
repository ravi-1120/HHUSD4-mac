import MultiObjectReferenceController from 'c/multiObjectReferenceController';
import LookupDataService from 'c/lookupDataService';
import VeevaUtils from 'c/veevaUtils';
import EXPENSE_HEADER from '@salesforce/schema/Expense_Header_vod__c';
import EVENT from '@salesforce/schema/Expense_Header_vod__c.Event_vod__c';
import ATTENDEE_NAME from '@salesforce/schema/EM_Attendee_vod__c.Attendee_Name_vod__c';
import SPEAKER_NAME from '@salesforce/schema/EM_Event_Speaker_vod__c.Speaker_Name_vod__c';
import EM_VENUE from '@salesforce/schema/EM_Venue_vod__c';
import {
  emLookupSearch,
  venueSearch,
  emLookupToSearchRecord,
  getInfiniteLoadingParam,
  isInfiniteLoadingEnabled,
  getColumnsAndSearch,
  searchWithColumns,
  getRecentLabel,
} from 'c/emObjectLookupSearch';
import VenueReferenceController from 'c/venueReferenceController';

const OBJECT_TO_NAME_FIELD = {
  EM_Attendee_vod__c: ATTENDEE_NAME.fieldApiName,
  EM_Event_Speaker_vod__c: SPEAKER_NAME.fieldApiName,
};

export default class ExpenseHeaderMultiLookupController extends MultiObjectReferenceController {
  location = ''; // Search for location on venue search modal

  get isVenueTargetObject() {
    return this.targetSObject === EM_VENUE.objectApiName;
  }

  get searchLookupTemplate() {
    return this.isVenueTargetObject ? VenueReferenceController.searchLookupTemplate : undefined;
  }

  constructor(meta, pageCtrl, field, record) {
    super(EXPENSE_HEADER.objectApiName, meta, pageCtrl, field, record);
    this.lookupDataSvc = new LookupDataService(pageCtrl.dataSvc);
  }

  get selected() {
    let ret = super.selected;
    if (ret && !ret.id && this._selected) {
      ret = this._selected;
    }
    if (ret && !ret.icon && this.selectedObject) {
      ret.icon = VeevaUtils.getIconHardcoded(this.selectedObject.value);
    }
    return ret;
  }

  // eslint-disable-next-line class-methods-use-this
  get nameField() {
    return 'Name';
  }

  getQueryParams(term) {
    return {
      field: this.selectedObject.field || '',
      q: term,
      refTo: this.selectedObject.value || '',
      id: this.data.rawValue(EVENT.fieldApiName),
      ...(this.location ? { location: this.location } : {}),
    };
  }

  getInfiniteLoadingParam(response, records) {
    return getInfiniteLoadingParam(response, records);
  }

  isInfiniteLoadingEnabled(response) {
    return isInfiniteLoadingEnabled(response);
  }

  getRecentLabel(targetObjectInfo) {
    return getRecentLabel(this, targetObjectInfo);
  }

  getColumnsAndSearch(term) {
    return getColumnsAndSearch(this, term);
  }

  searchWithColumns(term, offset) {
    return searchWithColumns(this, term, offset);
  }

  search(term, offset) {
    return this.isVenueTargetObject ? venueSearch(term, this, offset) : emLookupSearch(term, this, offset);
  }

  toSearchRecord(record) {
    const result = emLookupToSearchRecord(record, this._columns);
    result.name = record[OBJECT_TO_NAME_FIELD[this.selectedObject.value]] || record.Name || '';
    return result;
  }
}