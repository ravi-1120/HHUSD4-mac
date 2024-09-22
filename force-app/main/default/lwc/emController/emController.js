/* eslint-disable class-methods-use-this */
import VeevaPageController from 'c/veevaPageController';
import { fireEvent } from 'c/pubsub';
import EmEventConstant from 'c/emEventConstant';
import EmPageReference from 'c/emPageReference';
import EmRelatedListController from 'c/emRelatedListController';
import EmExpenseEstimateRelatedListController from 'c/emExpenseEstimateRelatedListController';
import EmExpenseLineRelatedListController from 'c/emExpenseLineRelatedListController';
import EmExpenseAttributionRelatedListController from 'c/emExpenseAttributionRelatedListController';
import EmExpenseHeaderRelatedListController from 'c/emExpenseHeaderRelatedListController';
import LookupDataReferenceController from 'c/lookupDataReferenceController';
import VenueReferenceController from 'c/venueReferenceController';
import VeevaUtils from 'c/veevaUtils';
import VeevaLayoutService from 'c/veevaLayoutService';
import { publish, createMessageContext } from 'lightning/messageService';
import { getService, SERVICES } from 'c/veevaServiceFactory';
import EM_VENUE from '@salesforce/schema/EM_Venue_vod__c';
import eventsManagementChannel from '@salesforce/messageChannel/Events_Management_Channel_vod__c';
import emCustomButtonTemplate from './emCustomButtonTemplate.html';

const POLL_DELAY = 3000;
const MAX_ATTEMPTS = 3;
const PLE_FIELDS = [
  'Event_vod__c',
  'Status_vod__c',
  'Start_Time_vod__c',
  'Country_vod__c',
  'Event_Configuration_vod__c',
  'Cvent_Meeting_Request_ID_vod__c',
];
const DATE_TIME_FIELDS = [
  'End_Date_vod__c',
  'End_Time_vod__c',
  'End_Time_Local_vod__c',
  'Start_Date_vod__c',
  'Start_Time_vod__c',
  'Start_Time_Local_vod__c',
];
const SAVEANDNEW_DISABLED_OBJECTS = ['EM_Event_vod__c', 'EM_Attendee_vod__c', 'EM_Event_Speaker_vod__c', 'Expense_Line_vod__c'];

export default class EmController extends VeevaPageController {
  _eventId = null;
  layoutFields = {};
  unlinkedDocumentIds = [];

  constructor(dataSvc, userInterface, messageSvc, metaStore, emPageLayoutEngineSvc) {
    super(dataSvc, userInterface, messageSvc, metaStore);
    this.emPageLayoutEngineSvc = this.getProxiedService(emPageLayoutEngineSvc);
    this.baseDataSvc = getService(SERVICES.BASE_DATA);
    // For New actions, check whether pageRef contains necessary PLE params
    this.pleParamsInPageRef = {};
    this.messageContext = createMessageContext();
  }

  /*
   * Used in Lookup Controller to make lookup icon in lookup fields clickable
   */
  get lookupIconClickable() {
    return true;
  }

  get shouldShowFileUpload() {
    const lockedEventStatusValues = ['Canceled_vod', 'Closed_vod'];
    const event = this.record.rawValue('Event_vod__r');
    return !(event?.fields?.Lock_vod__c?.value || lockedEventStatusValues.includes(event?.fields?.Status_vod__c?.value));
  }

  async initPageLayout() {
    const metadataPromise = this.loadMetadata();
    const [eventId, pleParams] = await Promise.all([this.getEventId(), this.getPleParams()]);
    const layout = await this.emPageLayoutEngineSvc.getPageLayout(
      this.objectInfo.apiName,
      this.page.action,
      this.record.id,
      this.record.recordTypeId,
      eventId,
      pleParams
    );
    if (this.action === 'View' && layout.relatedLists) {
      const relatedLists = this.getRelatedListsToDisplay(layout.relatedLists);
      fireEvent(this, EmEventConstant.POPULATE_RELATED_LIST_TABS, { relatedLists, pageCtrl: this });
    }
    const processedLayout = await this.processLayout(layout);
    await metadataPromise;
    await this.initData();
    this.page.layout = processedLayout;
    this.setButtons();
  }

  getRelatedListsToDisplay(relatedLists) {
    return relatedLists;
  }

  get canEdit() {
    const hasEditButton = this.page.layout?.buttons?.some(button => button.name === 'Edit');
    return super.canEdit && hasEditButton;
  }

  async loadMetadata() {
    // implement in sub-classes
  }

  async initData() {
    if (this.record.isNew) {
      this.filterDefaultFields();
    }
    this.updateReferenceFields();
  }

  processLayout(layout) {
    if (layout.sections) {
      this.layoutFields = {};
      layout.sections.forEach(section => {
        section.layoutRows = this.filterHiddenFields(section);
        section.layoutRows.forEach(row => {
          row.layoutItems.forEach(item => {
            this.layoutFields[item.field] = item;
          });
        });
      });
      layout.sections = VeevaLayoutService.filterEmptySections(layout.sections);
    }
    return layout;
  }

  filterHiddenFields(section) {
    const layoutItems = Array.from({ length: section.layoutRows[0].layoutItems.length }, () => []);
    section.layoutRows.forEach(row => {
      row.layoutItems.forEach((item, colIndex) => {
        if (this.isItemToHide(item)) {
          layoutItems[colIndex].push({ ...item, label: '' });
        } else if (!this.isItemToRemove(item)) {
          layoutItems[colIndex].push(item);
        }
      });
    });
    const maxColLength = Math.max(...layoutItems.map(col => col.length));
    layoutItems.forEach((col, i) => {
      while (col.length < maxColLength) {
        col.push({
          field: null,
          key: `${i}`,
          layoutComponents: [],
        });
      }
    });
    return layoutItems[0].map((col, key) => ({ key: `${key}`, layoutItems: layoutItems.map(row => row[key]) }));
  }

  /**
   * hidden items are replaced by a blank space
   */
  // eslint-disable-next-line no-unused-vars
  isItemToHide(item) {
    return false;
  }

  /**
   * removed items are removed entirely from the layout, and items below are shifted up
   */
  isItemToRemove(item) {
    return this.record.isNew && this.objectInfo.getFieldInfo(item.field)?.calculated;
  }

  isFieldOnLayout(fieldName) {
    return Boolean(this.layoutFields[fieldName]);
  }

  filterDefaultFields() {
    // Filter fields not part of the layout
    this.record.fields = Object.fromEntries(
      Object.entries(this.record.fields).filter(
        ([key]) =>
          this.layoutFields[key] ||
          !key.endsWith('__c') ||
          PLE_FIELDS.includes(key) ||
          DATE_TIME_FIELDS.includes(key) ||
          this.shouldKeepDefaultField(key)
      )
    );
  }

  // eslint-disable-next-line no-unused-vars
  shouldKeepDefaultField(fieldApiName) {
    return false;
  }

  async initRecordCreateBase(pageRef) {
    const { recordTypeId } = pageRef.state;
    const masterRt = this.objectInfo.getMasterRecordType();
    // eslint-disable-next-line @locker/locker/distorted-element-attributes-getter
    const apiName = pageRef.attributes.objectApiName;
    const objectFields = { ...this._objectInfo.fields };
    objectFields.RecordType = {
      apiName: 'RecordType.DeveloperName',
    };

    const [defaults, allMasterPicklists, allRtPicklists] = await Promise.all([
      EmPageReference.getCreateDefaults(this.uiApi, recordTypeId, apiName, objectFields, pageRef),
      this.uiApi.getPicklistValues(masterRt.recordTypeId, apiName, ''),
      this.uiApi.getPicklistValues(recordTypeId, apiName, ''),
    ]);

    this.addDefaultPicklistValues(defaults.record.fields, allMasterPicklists, allRtPicklists);

    this.record = defaults.record;
    this.record.assignRandomId();
    this.addDefaultFieldValues(pageRef.state);
    this.updateNewPageTitle();
  }

  initItemController(meta, record) {
    const field = this.objectInfo.getFieldInfo(meta.field);
    if (field?.referenceToInfos?.[0]?.apiName === EM_VENUE.objectApiName) {
      return new VenueReferenceController(meta, this, field, record);
    }
    if (field?.dataType === 'Reference') {
      return new LookupDataReferenceController(meta, this, field, record);
    }
    return super.initItemController(meta, record);
  }

  async initRecordCreate(pageRef) {
    await this.initRecordCreateBase(pageRef);
    this.pleParamsInPageRef = this.getPleParamsFromPageRef(pageRef.state);
    await this.initPageLayout();
  }

  getPleParamsFromPageRef(state) {
    return state?.inContextOfRef?.pleParams || {};
  }

  addDefaultPicklistValues(defaultFields, allMasterPicklists, allRtPicklists) {
    const picklistFieldValues = allMasterPicklists.picklistFieldValues || {};
    Object.keys(picklistFieldValues).forEach(picklistName => {
      const defaultPicklist = defaultFields[picklistName];
      let picklistToCopy = {};
      if (defaultPicklist.value) {
        // Compensate for getCreateDefaults not grabbing picklist displayName
        picklistToCopy = allRtPicklists.picklistFieldValues[picklistName];
      } else {
        // Replace blank rt defaults with field level defaults
        picklistToCopy = allMasterPicklists.picklistFieldValues[picklistName];
      }

      const { defaultValue } = picklistToCopy;
      if (defaultValue) {
        defaultPicklist.value = defaultValue.value;
        defaultPicklist.displayValue = defaultValue.label;
      }
    });
  }

  getRedirectPageRef() {
    if (this.page.action === 'Edit' && !this.canEdit) {
      return {
        type: 'standard__recordPage',
        attributes: {
          recordId: this.id,
          objectApiName: this.objectApiName,
          actionName: 'view',
        },
      };
    }

    return null;
  }

  async getEventId() {
    if (!this.record) {
      return null;
    }
    let eventId;
    if (this.record.apiName === 'EM_Event_vod__c') {
      eventId = this.record.id;
    } else {
      eventId = this.record.rawValue('Event_vod__c');
    }
    this._eventId = eventId;
    return eventId;
  }

  get eventId() {
    return this._eventId;
  }

  /**
   * For Edit and View pages reuse PLE fields queried in getQueryFields
   * For New Pages call ui-api with Event_vod__c default value
   * @returns {Object} containing PLE fields
   */
  async getPleParams() {
    let params = {};

    if (!this.objectInfo.getFieldInfo('Event_vod__c') || !this.record.rawValue('Event_vod__c')) {
      return params;
    }

    if (this.action !== 'New') {
      const event = this.record.rawValue('Event_vod__r');
      params = this.populatePleParams(event);
    } else if (this.pleParamsInPageRef && Object.keys(this.pleParamsInPageRef).length > 0) {
      params = this.pleParamsInPageRef;
    } else {
      const eventId = this.record.rawValue('Event_vod__c');
      const event = await this.uiApi.getRecord(eventId, [
        `EM_Event_vod__c.Status_vod__c`,
        `EM_Event_vod__c.Country_vod__r.Alpha_2_Code_vod__c`,
        `EM_Event_vod__c.Event_Configuration_vod__c`,
      ]);
      params = this.populatePleParams(event);
    }
    return params;
  }

  populatePleParams(event) {
    const params = {};
    if (event) {
      const eventLookupTraversal = VeevaUtils.lookupTraversal(event);
      params.eventStatus = eventLookupTraversal(['Status_vod__c']);
      params.countryAlpha2Code = eventLookupTraversal(['Country_vod__r', 'Alpha_2_Code_vod__c']);
      params.eventConfigId = eventLookupTraversal(['Event_Configuration_vod__c']);
      params.eventStartTime = eventLookupTraversal(['Start_Time_vod__c']);
      params.eventRecordTypeId = eventLookupTraversal(['RecordTypeId']);
    }
    return params;
  }

  /**
   * For Edit and View pages get PLE fields with the rest of the fields
   * @returns {Array} of query fields with appended PLE fields
   */
  getQueryFields() {
    let queryFields = super.getQueryFields();
    if (this.objectInfo.getFieldInfo('Event_vod__c')) {
      queryFields = queryFields.concat([
        `${this.objectApiName}.Event_vod__r.Status_vod__c`,
        `${this.objectApiName}.Event_vod__r.Start_Time_vod__c`,
        `${this.objectApiName}.Event_vod__r.Country_vod__r.Alpha_2_Code_vod__c`,
        `${this.objectApiName}.Event_vod__r.Event_Configuration_vod__c`,
        `${this.objectApiName}.Event_vod__r.RecordTypeId`,
      ]);
    }
    queryFields = queryFields.concat(this.getReferenceFieldNames());
    queryFields.push(`${this.objectApiName}.RecordType.DeveloperName`);
    return queryFields;
  }

  getOptionalQueryFields() {
    let queryFields = super.getOptionalQueryFields();
    if (this.objectInfo.getFieldInfo('Event_vod__c')) {
      queryFields = queryFields.concat([`${this.objectApiName}.Event_vod__r.Lock_vod__c`]);
    }
    return queryFields;
  }

  /**
   * @returns {Array} of fields containing queries for reference field names
   */
  getReferenceFieldNames() {
    const queryFields = [];
    Object.values(this.objectInfo.fields).forEach(fieldInfo => {
      const nameField = EmEventConstant.OBJECT_TO_NAME_FIELD[fieldInfo.referenceToInfos?.[0]?.apiName];
      if (fieldInfo?.relationshipName && nameField) {
        queryFields.push(`${this.objectApiName}.${fieldInfo.relationshipName}.${nameField}`);
      }
    });
    return queryFields;
  }

  updateReferenceFields(record) {
    const dataRecord = record || this.record;

    Object.keys(this.layoutFields).forEach(fieldApiName => {
      const fieldInfo = this.objectInfo.getFieldInfo(fieldApiName);
      const nameField = EmEventConstant.OBJECT_TO_NAME_FIELD[fieldInfo?.referenceToInfos?.[0]?.apiName];
      if (fieldInfo?.relationshipName && nameField) {
        const lookupField = dataRecord.rawValue(fieldInfo.relationshipName);
        const nameFieldValue = lookupField?.fields?.[nameField]?.displayValue || lookupField?.fields?.[nameField]?.value;
        if (nameFieldValue) {
          this.updateReferenceField(fieldInfo, nameFieldValue, dataRecord);
        }
      }
    });
  }

  updateReferenceField(fieldInfo, name, record) {
    const ref = record.reference(fieldInfo);
    ref.name = name;
    if (ref.name) {
      record.updateReferenceField(fieldInfo, ref);
    }
  }

  initTemplate(ctrl) {
    if (EmEventConstant.PLE_SUPPORTED_OBJECTS.includes(this.objectApiName) && ctrl.fieldApiName === EmEventConstant.EVENT && ctrl.displayValue) {
      // set Event lookup as read-only if it is populated
      ctrl.editable = false;
    }
    return super.initTemplate(ctrl);
  }

  async getModalButtons() {
    if (SAVEANDNEW_DISABLED_OBJECTS.includes(this.objectApiName)) {
      const buttonPromises = [this.createCancelButton()];

      if (this.action === 'New' || this.action === 'Edit') {
        buttonPromises.push(this.createSaveButton());
      }

      return Promise.all(buttonPromises);
    }
    return super.getModalButtons();
  }

  getRelatedListController(meta, pageCtrl) {
    let ctrl = null;
    if (EmEventConstant.PLE_SUPPORTED_OBJECTS.includes(meta.objectApiName)) {
      switch (meta.objectApiName) {
        case 'EM_Expense_Estimate_vod__c':
          ctrl = new EmExpenseEstimateRelatedListController(meta, pageCtrl);
          break;
        case 'Expense_Line_vod__c':
          ctrl = new EmExpenseLineRelatedListController(meta, pageCtrl);
          break;
        case 'Expense_Header_vod__c':
          ctrl = new EmExpenseHeaderRelatedListController(meta, pageCtrl);
          break;
        default:
          ctrl = new EmRelatedListController(meta, pageCtrl);
      }
    } else if (meta.objectApiName === 'Expense_Attribution_vod__c') {
      ctrl = new EmExpenseAttributionRelatedListController(meta, pageCtrl);
    }
    return ctrl;
  }

  async save(value) {
    const { pageRef } = value || { pageRef: {} };
    const result = await super.save(value);
    if (this.action === 'New') {
      await this.handleUnlinkedDocumentIdsSave(result?.Id);
    }
    if (result && this.isFlowScreen) {
      this.refreshRelatedList(pageRef);
    }
    return result;
  }

  async handleUnlinkedDocumentIdsSave(id) {
    if (!id || this.unlinkedDocumentIds.length === 0) {
      return;
    }
    const contentDocumentLinksToInsert = [];
    this.unlinkedDocumentIds.forEach(docId => {
      contentDocumentLinksToInsert.push({
        ContentDocumentId: docId,
        LinkedEntityId: id,
        ShareType: 'V',
      });
    });
    await this.baseDataSvc.updateRecords(contentDocumentLinksToInsert, 'ContentDocumentLink').catch(() => null);
    this.unlinkedDocumentIds = [];
  }

  refreshRelatedList(pageRef) {
    let payload;
    // eslint-disable-next-line @locker/locker/distorted-element-attributes-getter
    if (pageRef.state?.inContextOfRef?.relationship && pageRef.state.inContextOfRef.attributes?.recordId) {
      payload = {
        key: EmEventConstant.REFRESH_RELATED_LIST,
        // eslint-disable-next-line @locker/locker/distorted-element-attributes-getter
        parentId: pageRef.state.inContextOfRef.attributes.recordId,
        relationship: pageRef.state.inContextOfRef.relationship,
      };
    } else {
      payload = {
        key: EmEventConstant.REFRESH_RELATED_LISTS,
        eventId: this.eventId,
        objectApiName: this.objectApiName,
      };
    }
    publish(this.messageContext, eventsManagementChannel, payload);
  }

  getEmDefaultFieldValues() {
    const defVals = {};
    if (this.record?.rawValue('Event_vod__r')?.id) {
      defVals.Event_vod__c = {
        value: this.record.rawValue('Event_vod__r').id,
        displayValue: this.record.fields.Event_vod__r.displayValue,
      };
    } else if (this.record?.rawValue('Event_vod__c')) {
      defVals.Event_vod__c = this.record.fields.Event_vod__c;
    }
    return defVals;
  }

  getInContextOfRef(id) {
    const defVals = this.getEmDefaultFieldValues();

    const inContextOfRef = {
      type: 'standard__recordPage',
      attributes: {
        recordId: id,
        objectApiName: this.objectApiName,
        actionName: 'view',
      },
      emDefaultFieldValues: EmPageReference.encodeEmDefaultFieldValues(defVals),
    };
    return inContextOfRef;
  }

  getPageRefForSaveAndNew(id, pageState) {
    // eslint-disable-next-line no-param-reassign
    pageState.inContextOfRef = this.getInContextOfRef(id);

    const pageRef = super.getPageRefForSaveAndNew(id, pageState);

    pageRef.state.useRecordTypeCheck = true;
    const backgroundContext = this.getBackgroundContextForSaveAndNew(pageRef.state.inContextOfRef);
    if (backgroundContext) {
      pageRef.state.backgroundContext = backgroundContext;
    }
    return pageRef;
  }

  getBackgroundContextForSaveAndNew(inContextOfRef) {
    let backgroundPageRef;
    if (typeof inContextOfRef === 'string') {
      backgroundPageRef = JSON.parse(window.atob(inContextOfRef));
    } else {
      backgroundPageRef = inContextOfRef;
    }

    let url;
    let params = '';
    if (backgroundPageRef) {
      // eslint-disable-next-line @locker/locker/distorted-element-attributes-getter
      const attrs = backgroundPageRef.attributes;
      if (backgroundPageRef.type === 'standard__recordPage') {
        url = `/lightning/r/${attrs.objectApiName}/${attrs.recordId}/${attrs.actionName}`;
      } else if (backgroundPageRef.type === 'standard__objectPage') {
        url = `/lightning/o/${attrs.objectApiName}/${attrs.actionName}`;
      }

      if (backgroundPageRef.state) {
        const { state } = backgroundPageRef;
        for (const param in state) {
          if (Object.prototype.hasOwnProperty.call(state, param)) {
            if (typeof state[param] === 'object') {
              params = `${params}${param}=${JSON.stringify(state[param])}&`;
            } else {
              params = `${params}${param}=${state[param]}&`;
            }
          }
        }
      }

      if (url && params) {
        url = `${url}?${params}`;
      }
    }
    return url;
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

  addDefaultFieldValues(state) {
    if (state?.inContextOfRef?.emDefaultFieldValues) {
      const defVals = EmPageReference.decodeEmDefaultFieldValues(state.inContextOfRef.emDefaultFieldValues);
      Object.entries(defVals)
        .filter(([key]) => key !== 'RecordTypeId')
        .forEach(([key, value]) => {
          if (this.record.fields[key] || this.objectInfo.getFieldInfo(key)) {
            this.record.fields[key] = { ...value };
          }
        });
    }
  }

  getPageRefForDelete() {
    if (this.record?.fields?.Event_vod__c?.value) {
      return {
        type: 'standard__recordPage',
        attributes: {
          recordId: this.record.fields.Event_vod__c.value,
          objectApiName: 'EM_Event_vod__c',
          actionName: 'view',
        },
      };
    }
    return super.getPageRefForDelete();
  }

  useFlowNavAfterNew() {
    return true;
  }

  useFlowNavAfterEdit() {
    return true;
  }

  /**
   * Publishes a message to refresh a parent record
   * Has an option for the parent record to poll for the field updates
   * @param {Boolean} poll signals for parent record to poll before refresh
   * @param {String} parentId record to refresh
   * @param {Array} fieldsToPoll field to poll for changes
   */
  refreshParentRecordUi(poll, parentId, fieldsToPoll) {
    const payload = {
      key: EmEventConstant.REFRESH_PARENT_RECORD,
      poll,
      parentId,
      fieldsToPoll,
      POLL_DELAY,
      MAX_ATTEMPTS,
    };
    publish(this.messageContext, eventsManagementChannel, payload);
  }

  // eslint-disable-next-line class-methods-use-this
  toButtonCtrl(btn) {
    if (!btn.standard && !btn.notVeevaCustomButton) {
      return { template: emCustomButtonTemplate };
    }
    return undefined;
  }
}