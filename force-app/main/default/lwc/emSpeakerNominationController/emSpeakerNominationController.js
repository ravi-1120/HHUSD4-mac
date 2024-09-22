import VeevaPageController from 'c/veevaPageController';
import VeevaConstant from 'c/veevaConstant';
import ACCOUNT_FIELD from '@salesforce/schema/EM_Speaker_Nomination_vod__c.Account_vod__c';
import SPEAKER_FIELD from '@salesforce/schema/EM_Speaker_Nomination_vod__c.Speaker_vod__c';
import VeevaLayoutService from 'c/veevaLayoutService';
import VeevaUtils from 'c/veevaUtils';
import emSpeakerNominationButtonTemplate from './emSpeakerNominationButtonTemplate.html';

const EXCLUDED_SPEAKER_FIELDS = [ACCOUNT_FIELD.fieldApiName, 'Status_vod__c', 'Address_vod__c'];
const NOMINATION_TO_ACCOUNT_FIELD_MAPPING = { Title_vod__c: 'PersonTitle', First_Name_vod__c: 'FirstName', Last_Name_vod__c: 'LastName' };

export default class EmSpeakerNominationController extends VeevaPageController {
  constructor(dataSvc, userInterface, messageSvc, metaStore, emDataSvc) {
    super(dataSvc, userInterface, messageSvc, metaStore);
    this.emDataSvc = this.getProxiedService(emDataSvc);
    this.stampedFields = [];
    this.layoutFields = {};
    this.recalculateAddressField = false;
    this.objectInfosPromise = this.getRelatedObjectInfos();
    this.isSubmitForApprovalOnLayout = false;
    this.messageSvc.loadVeevaMessageCategories(['Common']);
  }

  async initPageLayout() {
    const layout = await this.uiApi.getPageLayoutNoButtons(this.objectInfo.apiName, this.page.action, this.record.recordTypeId);
    const buttons = await this.uiApi.getRecordActions(this.id, false);
    if (buttons?.actions?.[this.id]) {
      const { actions } = buttons.actions[this.id];
      this.isSubmitForApprovalOnLayout = actions.some(button => button.apiName === 'Submit');
      layout.buttons = VeevaLayoutService.toButtons(actions);
    } else {
      layout.buttons = [];
    }
    this.page.layout = await this.processLayout(layout);
    await this.setButtons();
  }

  async getRelatedObjectInfos() {
    const [accountObjectInfo, speakerObjectInfo] = await Promise.all([this.uiApi.objectInfo('Account'), this.uiApi.objectInfo('EM_Speaker_vod__c')]);
    this.accountObjectInfo = accountObjectInfo;
    this.speakerObjectInfo = speakerObjectInfo;
  }

  initItemController(meta, record) {
    const { field } = meta;
    if (this.stampedFields.includes(field)) {
      meta = { ...meta };
      meta.disabled = true;
    }
    return super.initItemController(meta, record);
  }

  async processLayout(layout) {
    super.processLayout(layout);
    this.populateLayoutFields(layout);
    await this.populateInitialStampedFields();
    return layout;
  }

  populateLayoutFields(layout) {
    if (layout.sections) {
      this.layoutFields = {};
      layout.sections.forEach(section => {
        section.layoutRows.forEach(row => {
          row.layoutItems.forEach(item => {
            this.layoutFields[item.field] = item;
          });
        });
      });
    }
  }

  async populateInitialStampedFields() {
    await this.objectInfosPromise;
    this.calculateFieldsToStamp();
    if (this.record.rawValue(SPEAKER_FIELD.fieldApiName)) {
      if (this.isNew) {
        await this.handleDependentFieldStamping(this.objectInfo.fields[SPEAKER_FIELD.fieldApiName], this.record.rawValue(SPEAKER_FIELD.fieldApiName));
      } else {
        this.stampedFields = this.speakerFieldsToStamp;
      }
    } else if (this.record.rawValue(ACCOUNT_FIELD.fieldApiName)) {
      if (this.isNew) {
        await this.handleDependentFieldStamping(this.objectInfo.fields[ACCOUNT_FIELD.fieldApiName], this.record.rawValue(ACCOUNT_FIELD.fieldApiName));
      } else {
        this.stampedFields = this.accountFieldsToStamp;
      }
    }
  }

  calculateFieldsToStamp() {
    this.accountFieldsToStamp = [];
    this.speakerFieldsToStamp = [];
    Object.keys(this.layoutFields).forEach(layoutField => {
      if (layoutField === 'Title_vod__c' || layoutField === 'First_Name_vod__c' || layoutField === 'Last_Name_vod__c'
          || (Object.prototype.hasOwnProperty.call(this.accountObjectInfo.fields, layoutField) && layoutField.endsWith('__c'))) {
        this.accountFieldsToStamp.push(layoutField);
      }
      if (Object.prototype.hasOwnProperty.call(this.speakerObjectInfo.fields, layoutField) && layoutField.endsWith('__c')
          && !EXCLUDED_SPEAKER_FIELDS.includes(layoutField)) {
        this.speakerFieldsToStamp.push(layoutField);
      }
    });
  }

  setFieldValue(field, value, reference, record, source) {
    super.setFieldValue(field, value, reference, record, source);
    this.handleDependentFieldStamping(field, value);
  }

  async handleDependentFieldStamping(field, value) {
    let obj = '';
    let callback = () => {};
    const fieldName = field.apiName;
    if (fieldName === ACCOUNT_FIELD.fieldApiName) {
      if (!this.record.rawValue(SPEAKER_FIELD.fieldApiName)) {
        obj = 'Account';
        callback = this.stampAccountFields.bind(this);
      }
      if (this.isFieldOnLayout('Address_vod__c')) {
        this.recalculateAddressField = true;
      }
    } else if (fieldName === SPEAKER_FIELD.fieldApiName) {
      obj = 'EM_Speaker_vod__c';
      callback = this.stampSpeakerFields.bind(this);
    }

    if (obj || this.recalculateAddressField) {
      if (obj) {
        this.clearStampedFields();
        await this.setDependentFields(obj, value, callback);
      }
      if (this.recalculateAddressField) {
        await this.setPreferredAddress();
      }
      this.page.recordUpdateFlag = !this.page.recordUpdateFlag;
    }
  }

  async setPreferredAddress() {
    const accountId = this.record.rawValue(ACCOUNT_FIELD.fieldApiName);
    let addressValue = null;
    if (accountId) {
      try {
        const address = await this.emDataSvc.getPreferredAddress(accountId);
        addressValue = address.Id;
      } catch (e) {
        addressValue = null;
      }
    }
    this.record.setFieldValue(this.objectInfo.fields.Address_vod__c, addressValue);
    this.recalculateAddressField = false;
  }

  async setDependentFields(obj, recordId, callback) {
    if (recordId) {
      const data = await this.uiApi.getRecord(recordId, this.getObjectQueryFields(obj));
      const { fields } = data;
      if (callback) {
        callback(fields);
      }
    }
  }

  getObjectQueryFields(obj) {
    let queryFields = [];
    if (obj === 'Account') {
      if (!this.accountQueryFields) {
        this.accountQueryFields = this.accountFieldsToStamp.map(nominationField => {
          let accountField = nominationField;
          if (Object.prototype.hasOwnProperty.call(NOMINATION_TO_ACCOUNT_FIELD_MAPPING, nominationField)) {
            accountField = NOMINATION_TO_ACCOUNT_FIELD_MAPPING[nominationField];
          }
          return `${obj}.${accountField}`;
        });
      }
      queryFields = this.accountQueryFields;
    } else if (obj === 'EM_Speaker_vod__c') {
      if (!this.speakerQueryFields) {
        this.speakerQueryFields = this.speakerFieldsToStamp.map(nominationField => `${obj}.${nominationField}`);
      }
      queryFields = this.speakerQueryFields;
    }
    return queryFields;
  }

  clearStampedFields() {
    this.stampedFields.forEach(field => {
      this.record.setFieldValue(this.objectInfo.fields[field], null);
      if (field === ACCOUNT_FIELD.fieldApiName && this.isFieldOnLayout('Address_vod__c')) {
        this.record.setFieldValue(this.objectInfo.fields.Address_vod__c, null);
        this.recalculateAddressField = false;
      }
    });
    this.stampedFields = [];
  }

  stampSpeakerFields(speakerFields) {
    this.speakerFieldsToStamp.forEach(speakerFieldToStamp => {
      const value = speakerFields[speakerFieldToStamp]?.value;
      this.record.setFieldValue(this.objectInfo.fields[speakerFieldToStamp], value);
      this.stampedFields.push(speakerFieldToStamp);
      if (speakerFieldToStamp === ACCOUNT_FIELD.fieldApiName && this.isFieldOnLayout('Address_vod__c')) {
        this.recalculateAddressField = true;
      }
    });
  }

  stampAccountFields(accountFields) {
    this.accountFieldsToStamp.forEach(accountFieldToStamp => {
      let accountFieldName = accountFieldToStamp;
      if (Object.prototype.hasOwnProperty.call(NOMINATION_TO_ACCOUNT_FIELD_MAPPING, accountFieldToStamp)) {
        accountFieldName = NOMINATION_TO_ACCOUNT_FIELD_MAPPING[accountFieldToStamp];
      }
      this.record.setFieldValue(this.objectInfo.fields[accountFieldToStamp], accountFields[accountFieldName]?.value);
      this.stampedFields.push(accountFieldToStamp);
    });
  }

  isFieldOnLayout(fieldName) {
    return Boolean(this.layoutFields[fieldName]);
  }

  async save(value) {
    const data = value?.data || this.getChanges();

    if (this.isNew && !value?.submit && !data[VeevaConstant.FLD_STATUS_VOD]) {
      data[VeevaConstant.FLD_STATUS_VOD] = VeevaConstant.SAVED_VOD;
    }

    return super.save({
      submit: value?.submit,
      data,
    });
  }

  get canEdit() {
    return this.objectInfo.updateable;
  }

  get canDelete() {
    return this.objectInfo.deletable;
  }

  async getHeaderButtons() {
    let buttons = this.page.layout.buttons || [];
    buttons = buttons.filter(x => !x.edit);
    if (this.record.isLocked) {
      buttons = buttons.filter(x => x.name !== 'Edit' && x.name !== 'Delete');
    }
    if (!this.record.isLocked && !this.record.rawValue('IsLocked')) {
      if (this.isSubmitForApprovalOnLayout) {
        // SF Submit For Approval button
        const submitForApprovalLabel = await this.messageSvc.getMessageWithDefault('SUBMIT_FOR_APPROVAL', 'Common', 'Submit for Approval');
        buttons.push({ name: 'SubmitForApproval', label: submitForApprovalLabel });
      } else {
        // standard Veeva submit button
        const submitLabel = await this.messageSvc.getMessageWithDefault('SUBMIT', 'Common', 'Submit');
        buttons.push({ name: 'submit', label: submitLabel, notVeevaCustomButton: true });
      }
    }
    if (this.isUnlockable()) {
      buttons.push({ name: 'Unlock', standard: true });
    }
    return buttons;
  }

  isUnlockable() {
    return (
      this.record.isLocked &&
      !this.record.rawValue('IsLocked') &&
      this.objectInfo.updateableField(VeevaConstant.FLD_LOCK_VOD) &&
      this.objectInfo.updateableField('Override_Lock_vod__c') &&
      this.objectInfo.updateableField(VeevaConstant.FLD_STATUS_VOD)
    );
  }

  unlock() {
    return super.unlock({
      type: this.objectApiName,
      Id: this.id,
      Status_vod__c: VeevaConstant.SAVED_VOD,
      Lock_vod__c: false
    });
  }

  // eslint-disable-next-line class-methods-use-this
  toButtonCtrl(btn) {
    let buttonCtrl;
    if (btn.name === 'SubmitForApproval') {
      buttonCtrl = { template: emSpeakerNominationButtonTemplate };
    }
    return buttonCtrl;
  }

  getPageRefForClose(id, saveAndNew, pageState) {
    let pageRef;
    if (!saveAndNew && VeevaUtils.validSfdcId(id)) {
      pageRef = {
        type: 'standard__recordPage',
        attributes: {
          recordId: id,
          objectApiName: this.objectApiName,
          actionName: 'view',
        },
      };
    } else {
      pageRef = super.getPageRefForClose(id, saveAndNew, pageState);
    }
    return pageRef;
  }
}