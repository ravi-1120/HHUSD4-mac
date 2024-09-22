import MultiObjectReferenceController from 'c/multiObjectReferenceController';
import LookupDataService from 'c/lookupDataService';
import EmEventConstant from 'c/emEventConstant';
import { emLookupSearch, emLookupToSearchRecord, getInfiniteLoadingParam, isInfiniteLoadingEnabled, getColumnsAndSearch, searchWithColumns, getRecentLabel } from 'c/emObjectLookupSearch';

export default class EmNextApproverController extends MultiObjectReferenceController {
  constructor(objectApiName, meta, pageCtrl, model) {
    super(objectApiName, meta, pageCtrl, {}, pageCtrl.record);
    this.model = model;
    this.lookupDataSvc = new LookupDataService(pageCtrl.dataSvc);
  }

  get selected() {
    let ret = super.selected;
    if (ret && !ret.id && this._selected) {
      ret = this._selected;
    }
    return ret;
  }

  get nameField() {
    return 'Name';
  }

  setFieldValue(id, detail) {
    this._selected = detail;
    if (id) {
      this.model[EmEventConstant.APPROVER_ID] = id;
    } else {
      delete this.model[EmEventConstant.APPROVER_ID];
    }
  }

  getQueryParams(term) {
    return {
      q: term,
      field: this.getField(),
      refTo: this.targetSObject,
    };
  }

  getField() {
    let fieldName = '';
    if (this.targetSObject === 'User') {
      fieldName = 'NextApprover';
    } else if (this.targetSObject === 'Group') {
      fieldName = 'Queue';
    }
    return fieldName;
  }

  toSearchRecord(record) {
    return emLookupToSearchRecord(record, this._columns);
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
    return emLookupSearch(term, this, offset);
  }
}