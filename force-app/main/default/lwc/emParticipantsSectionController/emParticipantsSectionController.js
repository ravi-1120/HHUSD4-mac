import VeevaSectionController from 'c/veevaSectionController';
import VeevaConstant from 'c/veevaConstant';
import { getService, SERVICES } from 'c/veevaServiceFactory';
import VeevaUtils from 'c/veevaUtils';

import getParticipantGroups from '@salesforce/apex/EmExpensesController.getParticipantGroups';
import ACTUAL from '@salesforce/schema/Expense_Line_vod__c.Actual_vod__c';
import EVENT from '@salesforce/schema/Expense_Header_vod__c.Event_vod__c';
import EXPENSE_ATTR from '@salesforce/schema/Expense_Attribution_vod__c';
import INCURRED_EXPENSE_TYPE from '@salesforce/schema/Expense_Attribution_vod__c.Incurred_Expense_Type_vod__c';

import template from './emParticipantsSectionController.html';

const INCURRED_EXPENSE_TYPE_TO_FIELD = {
  Account_vod: 'Incurred_Expense_Account_vod__c',
  Attendee_vod: 'Incurred_Expense_Attendee_vod__c',
  Event_Speaker_vod: 'Incurred_Expense_Speaker_vod__c',
  Event_Team_Member_vod: 'Incurred_Expense_Team_Member_vod__c',
  Vendor_vod: 'Incurred_Expense_Vendor_vod__c',
  Venue_vod: 'Incurred_Expense_Venue_vod__c',
};

export default class EmParticipantsSectionController extends VeevaSectionController {
  constructor(meta, pageCtrl) {
    super(meta, pageCtrl);
    this.splitExpenseLine = this.pageCtrl.getSplitExpenseLine();
    this.dataStore = getService(SERVICES.BYPASS_PROXY_DATA_STORE);
  }

  initTemplate() {
    this.template = template;
    return this;
  }

  get expenseLineId() {
    return this.splitExpenseLine?.record?.id;
  }

  get isMultiCurrency() {
    return !!this.pageCtrl.objectInfo.getFieldInfo(VeevaConstant.FLD_CURRENCY_ISO_CODE);
  }

  get isView() {
    return this.pageCtrl.page.action === 'View';
  }

  async getGroups() {
    if (this.isView) {
      return [];
    }

    const params = { eventId: this.pageCtrl.record.rawValue(EVENT.fieldApiName) };
    if (VeevaUtils.validSfdcId(this.expenseLineId)) {
      params.expenseLineId = this.expenseLineId;
    }
    try {
      const [groups] = await Promise.all([getParticipantGroups(params), this.loadTypePicklistValues()]);
      return groups;
    } catch (error) {
      return [];
    }
  }

  async loadTypePicklistValues() {
    const attrRecordTypeId = this.pageCtrl.expenseAttrInfo.defaultRecordTypeId;
    this.typePicklistValues = await this.pageCtrl.uiApi.getPicklistValues(
      attrRecordTypeId,
      EXPENSE_ATTR.objectApiName,
      INCURRED_EXPENSE_TYPE.fieldApiName
    );
  }

  getParticipants() {
    const splitAmountPerPerson = this.pageCtrl.getSplitAmountPerPerson()?.toFixed(2);
    return this.splitExpenseLine.attributions
      .filter(attribution => !attribution.Deleted)
      .map(attribution => ({
        ...attribution,
        actual: this.isView ? attribution.Actual_vod__c : splitAmountPerPerson,
      }));
  }

  getActual() {
    return this.splitExpenseLine.record.rawValue(ACTUAL.fieldApiName) ?? 0;
  }

  getCurrency() {
    return this.splitExpenseLine.record.rawValue(VeevaConstant.FLD_CURRENCY_ISO_CODE);
  }

  addParticipants(participants) {
    participants.forEach(participant => this.addParticipant(participant));
  }

  addParticipant(participant) {
    // find existing participant
    const incurredExpenseField = INCURRED_EXPENSE_TYPE_TO_FIELD[participant.type];
    const existingParticipant = this.splitExpenseLine.attributions.find(a => a.participantId === participant.participantId);
    if (existingParticipant) {
      // undelete if necessary
      delete existingParticipant.Deleted;
    } else {
      // add new participant
      this.splitExpenseLine.attributions.push({
        ...participant,
        Incurred_Expense_vod__c: participant.name,
        Incurred_Expense_Type_vod__c: participant.type,
        toLabel_Incurred_Expense_Type_vod__c: this.getIncurredExpenseTypeLabel(participant.type),
        [incurredExpenseField]: participant.participantId,
        Id: VeevaUtils.getRandomId(),
      });
    }
  }

  getIncurredExpenseTypeLabel(type) {
    const picklistVal = this.typePicklistValues?.values?.find(value => value.value === type);
    return picklistVal?.label ?? type;
  }

  deleteParticipant(id) {
    if (VeevaUtils.validSfdcId(id)) {
      const attr = this.splitExpenseLine.attributions.find(a => a.Id === id);
      if (attr) attr.Deleted = 'true';
    } else {
      this.splitExpenseLine.attributions = this.splitExpenseLine.attributions.filter(a => a.Id !== id);
    }
  }

  updateAttributionsFromDataStore(dataStoreId) {
    this.splitExpenseLine.attributions = this.dataStore.retrieve(dataStoreId);
    this.dataStore.remove(dataStoreId);
  }
}