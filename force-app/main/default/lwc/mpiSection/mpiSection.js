import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import MedInqConstant from 'c/medInqConstant';
import VeevaConstant from 'c/veevaConstant';
import { getNestedFieldErrors } from 'c/veevaPageFieldErrors';
import VeevaErrorHandlerMixin from 'c/veevaErrorHandlerMixin';

export default class MpiSection extends VeevaErrorHandlerMixin(NavigationMixin(LightningElement)) {
  @api ctrl;
  @track records = [];
  labelAddSection;
  labelCopy;
  labelDel;
  validityElementsSelector = 'c-veeva-mpi-section-record';

  @api get recordUpdateFlag() {
    return this._recordUpdateFlag;
  }

  set recordUpdateFlag(value) {
    this.ctrl.getRecords().then(records => {
      this.records = records;
      this._recordUpdateFlag = value;
    });
  }

  get displayAddSectionCopy() {
    return (
      !this.ctrl.actionView &&
      !this.ctrl.data.isLocked &&
      !this.ctrl.data.isFieldSet(VeevaConstant.FLD_SIGNATURE_DATE_VOD) &&
      this.ctrl.pageCtrl.objectInfo.getFieldInfo(MedInqConstant.GROUP_IDENTIFIER) &&
      this.ctrl.pageCtrl.objectInfo.createable
    );
  }

  get displayDeleteLink() {
    return (
      !this.ctrl.actionView &&
      !this.ctrl.data.isLocked &&
      !this.ctrl.data.isFieldSet(VeevaConstant.FLD_SIGNATURE_DATE_VOD) &&
      this.ctrl.pageCtrl.objectInfo.getFieldInfo(MedInqConstant.GROUP_IDENTIFIER) &&
      this.ctrl.pageCtrl.objectInfo.deletable
    );
  }

  async connectedCallback() {
    // Get records first
    this.records = await this.ctrl.getRecords();

    if (!this.ctrl.actionView) {
      this.ctrl.pageCtrl.getMessageWithDefault('ADD_SECTION_MPI', 'MEDICAL_INQUIRY', 'Add Section').then(data => {
        this.labelAddSection = data;
      });
      this.ctrl.pageCtrl.getMessageWithDefault('COPY', 'CallReport', 'Copy').then(data => {
        this.labelCopy = data;
      });
      this.ctrl.pageCtrl.getMessageWithDefault('Del', 'Common', 'Del').then(data => {
        this.labelDel = data;
      });
    }
  }

  addInquiry() {
    this.ctrl.addInquiry().then(inquiry => {
      this.records = [...this.records, inquiry];
    });
  }

  copyInquiry(event) {
    const inquiry = this.ctrl.copyInquiry(event.detail.id);
    this.records = [...this.records, inquiry];
  }

  @api deleteInquiry(event) {
    this.ctrl.deleteInquiry(event.detail.id);
    this.records = this.records.filter(x => x.id !== event.detail.id);
  }

  @api getFieldErrors() {
    const fieldErrors = getNestedFieldErrors(this.getDataValidityElements(), 'c-mpi-section');
    if (!fieldErrors.length) {
      this.ctrl.saveCheckpoint();
    }
    return fieldErrors;
  }
}