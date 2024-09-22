import ReferenceController from 'c/referenceController';
import LookupDataService from 'c/lookupDataService';
import { emLookupSearch, emLookupToSearchRecord, emLookupGetQueryParams, getInfiniteLoadingParam, isInfiniteLoadingEnabled, getColumnsAndSearch, searchWithColumns, getRecentLabel } from 'c/emObjectLookupSearch';
import EmEventConstant from 'c/emEventConstant';

export default class LookupDataReferenceController extends ReferenceController {
  constructor(item, pageCtrl, field, record) {
    super(item, pageCtrl, field, record);
    this.lookupDataSvc = new LookupDataService(pageCtrl.dataSvc);
  }

  get nameField() {
    return EmEventConstant.OBJECT_TO_NAME_FIELD[this.targetSObject] ?? super.nameField;
  }

  getQueryParams(term) {
    return emLookupGetQueryParams(term, this);
  }

  toSearchRecord(record) {
    return emLookupToSearchRecord(record, this._columns);
  }

  // eslint-disable-next-line no-unused-vars
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
    return emLookupSearch(term, this, offset);
  }
}