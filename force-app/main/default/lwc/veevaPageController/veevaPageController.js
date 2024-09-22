/* eslint-disable class-methods-use-this */
import VeevaObjectInfo from 'c/veevaObjectInfo';
import VeevaRecord from 'c/veevaRecord';
import VeevaConstant from 'c/veevaConstant';
import VeevaLayoutService from 'c/veevaLayoutService';
import ControllerFactory from 'c/controllerFactory';
import VeevaUtils from 'c/veevaUtils';
import VeevaPageReference from 'c/veevaPageReference';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import VeevaLayoutParser from 'c/veevaLayoutParser';

export default class VeevaPageController {
  constructor(dataSvc, userInterface, messageSvc, metaStore, appMetricsService) {
    this.dataSvc = this.getProxiedService(dataSvc);
    this.uiApi = this.getProxiedService(userInterface);
    this.metaStore = this.getProxiedService(metaStore);
    this.messageSvc = messageSvc;
    this.pageMetricsService = appMetricsService?.createPageMetricsService();
  }

  // Use 'page' to notify the View of changes.
  get page() {
    return this._page;
  }
  set page(value) {
    this._page = value;
  }
  // Model
  get record() {
    return this._record;
  }
  set record(value) {
    this._record = this.toVeevaRecord(value);
    // once the record is set, we can set the page information for metric reporting
    this.setMetricTags();
  }
  // metadata
  get objectInfo() {
    return this._objectInfo;
  }
  set objectInfo(value) {
    this._objectInfo = this.toVeevaObjectInfo(value);
  }

  get id() {
    return this._record ? this._record.id : '';
  }

  get recordId() {
    // for pubsub module fireEvent
    return this.id;
  }

  get objectApiName() {
    return this._objectInfo ? this._objectInfo.apiName : null;
  }

  get objectLabel() {
    return this.objectInfo.label;
  }

  get action() {
    return this.page ? this.page.action : undefined;
  }

  get isClone() {
    return this._isClone;
  }

  get isNew() {
    return this.page && this.page.action === 'New';
  }

    get statusFieldName() {
        // default status field name; override this as necessary in subclasses
        return 'Status_vod__c';
    }

    /*
     * Used in Lookup Controller to make lookup icon in lookup fields clickable
     */
    get lookupIconClickable() {
        return false;
    }

    async updateRecordStatus(pageReference) {
        if (pageReference && pageReference.state && pageReference.state.c__pageRefStatus === 'Unlocking') {
            this.record.fields[this.statusFieldName] = await this.uiApi.getRecord(this.recordId, [`${this.objectApiName}.${this.statusFieldName}`]);
        }
    }

    async shouldDisplayAttachmentsList() {
        const relatedLists = await this.fetchRelatedListInfo();
        return relatedLists.some(relatedList => relatedList.objectApiName === 'CombinedAttachment');
    }

  async fetchRelatedListInfo() {
    const relatedListsResponse = await this.uiApi.getRelatedLists(this.objectApiName, this.record.recordTypeId);
    if (relatedListsResponse && relatedListsResponse.relatedLists) {
      return relatedListsResponse.relatedLists;
    }

    return [];
  }

  get isEdit() {
    return this.page && this.page.action === 'Edit';
  }

  get shouldShowFileUpload() {
    return !this.record.isLocked;
  }

  getPageIcon() {
    return VeevaUtils.getIconFromUrl(this.objectInfo.themeInfo.iconUrl);
  }

  async getEditPageTitle() {
    return this.getMessageWithDefault('Edit', 'Common', 'Edit').then(edit => {
      if (this.record?.name) {
        return `${edit} ${this.record.name}`;
      }
      if (this.objectInfo?.label) {
        return `${edit} ${this.objectInfo.label}`;
      }
      return edit;
    });
  }

  getPageTitle() {
    return this.objectInfo.label;
  }

  getPageSubtitle() {
    return this.record.name;
  }

  getPageMetricsService() {
    return this.pageMetricsService;
  }

  setMetricTags() {
    if (this.pageMetricsService) {
      this.pageMetricsService.name = this.pageMetricsService.formatPageName(this.action, this.record.apiName);

      const uuid = this.pageMetricsService.generateUUID();

      this.pageMetricsService.tags = {
        action: this.action,
        object: this.record.apiName,
        pageId: this.record.id || uuid,
        recordTypeId: this.record.recordTypeId,
      };
    }
  }

  toVeevaObjectInfo(value) {
    return value instanceof VeevaObjectInfo ? value : new VeevaObjectInfo(value);
  }

  toVeevaRecord(value) {
    return value instanceof VeevaRecord ? value : new VeevaRecord(value);
  }

  getQueryFields() {
    return this._objectInfo.getQueryFields();
  }

  getOptionalQueryFields() {
    return [];
  }

  async initPageLayout() {
    const layout = await this.uiApi.getPageLayout(this.objectInfo.apiName, this.page.action, this.record.recordTypeId, this.id);
    await this.initMetadata(layout);
    const processedLayout = await this.processLayout(layout);
    await this.initData();
    this.page.layout = processedLayout;
    await this.setButtons();
  }

  async checkRecordCreateRestrictions(pageRef) {// eslint-disable-line no-unused-vars
    return true;
  }

  async initRecordCreate(pageRef) {
    await this.checkRecordCreateRestrictions(pageRef);

    const emptyRecord = new VeevaRecord({});
    if (emptyRecord.isMasterRecordType(pageRef.state.recordTypeId)) {
      const availableRecordType = this.getFirstAvailableRecordType();
      pageRef.state.recordTypeId = availableRecordType.recordTypeId;
      this._objectInfo.defaultRecordTypeId = availableRecordType.recordTypeId;
    }
    const defaults = await VeevaPageReference.getCreateDefaults(pageRef, this.uiApi);
    const defVals = pageRef.state.defaultFieldValues && JSON.parse(pageRef.state.defaultFieldValues);
    this._isClone = defVals && defVals.isClone;

    this.record = defaults.record;
    this.record.assignRandomId();
    await this.addDefaultFieldValues(pageRef.state);
    await this.initMetadata(defaults.layout);
    const processedLayout = await this.processLayout(defaults.layout);
    await this.initData();
    this.page.layout = processedLayout;
    await this.setButtons();
    await this.updateNewPageTitle();
  }

  async updateNewPageTitle() {
    if (!this.titleTemplate) {
      this.titleTemplate = await this.getMessageWithDefault('NEW', 'Common', 'New');
    }

    const recordTypeLabel = (this.record.recordTypeInfo && this.record.recordTypeInfo.name) || '';
    if (recordTypeLabel === '') {
      this.page.title = `${this.titleTemplate} ${this.objectInfo.label}`;
    } else {
      this.page.title = `${this.titleTemplate} ${this.objectInfo.label}: ${recordTypeLabel}`;
    }
  }

  getFirstAvailableRecordType() {
    const recordTypeArr = Object.values(this._objectInfo.recordTypeInfos).filter(val => val.available);
    recordTypeArr.sort((a, b) => a.name.localeCompare(b.name));
    recordTypeArr.sort((a, b) => a.master - b.master); // Push the master Record Type to the end
    return recordTypeArr[0];
  }

  async initMetadata(layout) {
    const layoutParser = this.getLayoutParser(layout);
    layoutParser.parseLayout();
  }

  getLayoutParser(layout) {
    return new VeevaLayoutParser(layout);
  }

  async processLayout(layout) {
    let processedLayout = layout;

    const layoutAdapter = this.getLayoutAdapter(layout);
    if (layoutAdapter) {
      layoutAdapter.processLayout();
      processedLayout = layoutAdapter.getLayout();
    }
    return processedLayout;
  }

  getLayoutAdapter(layout) {// eslint-disable-line no-unused-vars
    // implement in sub-classes
  }

  async initData() {
    return; // eslint-disable-line no-useless-return
  }

  async setButtons() {
    this.page.modalButtons = await this.getModalButtons();
    this.page.modalButtons = this.setButtonVariant(this.page.modalButtons);
  }

  setButtonVariant(buttons) {
    function isSubmitPartOfModalButtons() {
      return buttons.findIndex(btn => btn.name === 'submit') > -1;
    }

    buttons.forEach(btn => {
      if (btn.name === 'save' && isSubmitPartOfModalButtons()) {
        btn.variant = 'brand-outline';
      } else if (btn.name === 'save' || btn.name === 'submit') {
        btn.variant = 'brand';
      }
    });

    return buttons;
  }

  async getCompactLayoutMetadata() {
    const MAX_COMPACT_LAYOUT_FIELDS = 7;
    const { recordTypeId } = this.record;
    const layout = await this.uiApi.getCompactLayout(this.objectApiName, 'View', recordTypeId);
    const compactLayoutMetadata = [];
    if (layout && layout.data) {
      for (const section of layout.data.sections) {
        for (const row of section.layoutRows) {
          for (const item of row.layoutItems) {
            for (const component of item.layoutComponents) {
              if (compactLayoutMetadata.length < MAX_COMPACT_LAYOUT_FIELDS) {
                compactLayoutMetadata.push(component);
              }
            }
          }
        }
      }
    }
    return compactLayoutMetadata;
  }

    getItemController(meta, record, resetCtrl) {
        const dataRecord = record || this.record;
        const ctrl = this.initItemController(meta, dataRecord, resetCtrl);
        return this.initTemplate(ctrl);
    }

    // eslint-disable-next-line no-unused-vars
    initItemController(meta, record, resetCtrl) {
        return ControllerFactory.itemController(meta, this, record);
    }

  initTemplate(ctrl) {
    return ctrl.initTemplate();
  }

  getSectionController(meta) {
    return ControllerFactory.sectionController(meta, this).initTemplate();
  }

  getSideBarController(meta) {
    return ControllerFactory.sideBarController(meta, this).initTemplate();
  }

  hasSideBar() {
    return false;
  }

  async save(value = {}) {
    const data = value.data || this.getChanges();
    if (value.submit) {
      this.setSubmit(data);
    }
    try {
      const response = await this.doSave(data);
      // Notify LDS cache of record update
      await this.processForLDSCache(data);
      return this.getPageRefAfterSave(response.data);
    } catch (error) {
      this.processError(error.data);
      // eslint-disable-next-line prefer-promise-reject-errors
      return Promise.reject({ recordErrors: this._recordErrors, fieldErrors: this.fieldErrors });
    }
  }

  async doSave(data) {
    return this.dataSvc.save(data);
  }

  delete() {
    return this.save({ data: { Deleted: 'true', Id: this.id, type: this.objectInfo.objectApiName } });
  }

  validate() {
    return true;
  }

  getPageRefAfterSave(data) {
    return data;
  }

  getChanges() {
    return this.record.getChanges(this.objectInfo);
  }

  setSubmit(data) {
    if (data && !data.Deleted) {
      if (VeevaUtils.isEmptyObject(data) && !this.record.isNew) {
        data.Id = this.record.id;
        data.type = this.record.apiName;
      }
      data[VeevaConstant.FLD_STATUS_VOD] = VeevaConstant.SUBMITTED_VOD;
    }
  }

  unlock(data) {
    const saveData = data || {
      type: this.objectApiName,
      Id: this.id,
      Lock_vod__c: false,
    };
    return this.save({
      data: saveData,
    });
  }

  setFieldValue(field, value, reference, record, source) {
    const dataRecord = record || this.record;
    dataRecord.setFieldValue(field, value, reference);
    this.updateDependencies(field.apiName || field, value, dataRecord, source);
  }

  updateDependencies(field, value, record, source) {
    if (this.__watch) {
      let watchKey = field;
      if (record) {
        watchKey = this._getWatchKey(field, record.id);
      }
      const watchers = this.__watch[watchKey];
      if (watchers) {
        watchers.forEach(x => x.context[x.handler](value, source));
      }
    }
  }

    track(key, context, handler) {
        // define non enumerable property so it won't be cloned
        if (!this.__watch) {
            Object.defineProperty(this, '__watch', { value: {} });
        }
        let recordId;
        if (context.ctrl) {
            recordId = context.ctrl.id;
        }
        const watchKey = this._getWatchKey(key, recordId);      
        if (!this.__watch[watchKey]) {
            this.__watch[watchKey] = [];
        }
        if (!this.__watch[watchKey].map(x => x.context).includes(context)) {
            this.__watch[watchKey].push({ context, handler });
        }
    }

  _getWatchKey(fieldName, recordId) {
    return `${recordId}_${fieldName}`;
  }

  toDelete() {
    this.deleted = true;
    this.record.Deleted = true;
  }

  undelete() {
    delete this.deleted;
    delete this.record.Deleted;
  }

  // this is async because child implementations may be async (like in MedicalInquiryController)
  isSubmitButtonAvailable() {
    return this.isButtonAvailable(VeevaConstant.SUBMIT_VOD);
  }

  isButtonAvailable(btnName) {
    return VeevaLayoutService.getButton(this.page.layout, btnName);
  }

  get canCreate() {
    return this.objectInfo.createable;
  }

  get canEdit() {
    return this.objectInfo.updateable && this.record.isEditable;
  }

  get canDelete() {
    return this.objectInfo.deletable && this.record.isDeletable;
  }

  getDataForClone(skips) {
    const data = this.record.getDataForClone(this.objectInfo, skips || []);
    data.retURL = `/lightning/r/${data.type}/${this.record.id}/view`;
    data.isClone = true;
    return data;
  }

  // the defaultFieldValues are used on Clone
  addDefaultFieldValues(state, record) {
    const recordToUpdate = record || this.record;

    if (state.defaultFieldValues) {
      const values = JSON.parse(state.defaultFieldValues);
      Object.entries(values).forEach(([key, value]) => {
        if (recordToUpdate.fields[key] || this.objectInfo.getFieldInfo(key)) {
          recordToUpdate.fields[key] = value;
          if (key === 'RecordTypeId' && value && value.value) {
            recordToUpdate.recordTypeId = value.value;
          }
        } else {
          recordToUpdate[key] = value;
        }
      });
    }
  }

  getHeaderButtons() {
    let buttons = this.page.layout.buttons || [];
    buttons = buttons.filter(x => !x.edit);
    if (this.record.isSubmitted) {
      buttons = buttons.filter(x => x.name !== 'Edit' && x.name !== 'Delete');
    }
    return buttons;
  }

  async getModalButtons() {
    const buttonPromises = [this.createCancelButton()];

    if (this.action === 'New' || this.action === 'Edit') {
      if (this.canCreate) {
        buttonPromises.push(this.createSaveAndNewButton());
      }
      buttonPromises.push(this.createSaveButton());
      if (await this.isSubmitButtonAvailable()) {
        buttonPromises.push(this.createSubmitButton());
      }
    }

    return Promise.all(buttonPromises);
  }

  createSaveButton() {
    return this._createCommonModalButton('save', 'SAVE', 'Save');
  }

  createSaveAndNewButton() {
    return this.createModalButton('saveAndNew', 'SAVENEW', 'CallReport', 'Save and New');
  }

  createSubmitButton() {
    return this._createCommonModalButton('submit', 'SUBMIT', 'Submit');
  }

  createCancelButton() {
    return this._createCommonModalButton('cancel', 'CANCEL', 'Cancel');
  }

  _createCommonModalButton(name, key, def) {
    return this.createModalButton(name, key, 'Common', def);
  }

  async createModalButton(name, key, category, def) {
    return {
      name,
      label: await this.getMessageWithDefault(key, category, def),
      notVeevaCustomButton: true,
    };
  }

  processError(data) {
    this.clearErrors();
    if (data) {
      if (data.recordErrors) {
        data.recordErrors.forEach(x => this.addRecordError(x));
      }
      if (data.fieldErrors) {
        const fieldErrors = { ...data.fieldErrors };
        this.fieldErrors = { [this.record.id]: fieldErrors };
      }
    }
  }

  async setRecordError(msgName, category, defMsg) {
    const msg = await this.getMessageWithDefault(msgName, category, defMsg);
    this.addRecordError(msg);
  }

  addRecordError(msg) {
    this._recordErrors = this._recordErrors || [];
    if (msg) {
      this._recordErrors.push(msg);
    }
  }

  get recordErrors() {
    return this._recordErrors;
  }

  clearErrors() {
    this._recordErrors = [];
    this.fieldErrors = {};
  }

  getRedirectPageRef() {
    if (this.page.action === 'Edit' && this.record.isLocked) {
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

  async processForLDSCache(data) {
    if (data && data.Id && !data.Deleted) {
      this.notifyLDSCache([{ recordId: data.Id }]);
    }
  }

  async notifyLDSCache(recordIds) {
    // doing this because we can't spy on getRecordNotifyChange (hacky; don't want to make a habit of this)
    getRecordNotifyChange(recordIds);
  }

  async getMessageWithDefault(key, category, defaultMessage) {
    return this.messageSvc.getMessageWithDefault(key, category, defaultMessage);
  }

  async getMessageMap(msgRequest) {
    return this.messageSvc.getMessageMap(msgRequest);
  }

  getPageRefForSaveAndNew(id, pageState) {
    const { inContextOfRef } = pageState;
    const pageRef = {
      type: 'standard__objectPage',
      attributes: {
        objectApiName: this.objectApiName,
        actionName: 'new',
      },
    };

    if (inContextOfRef) {
      if (typeof inContextOfRef === 'object') {
        pageRef.state = {
          inContextOfRef: window.btoa(JSON.stringify(inContextOfRef)),
        };
      } else {
        pageRef.state = {
          inContextOfRef,
        };
      }
    } else {
      pageRef.state = {
        inContextOfRef: window.btoa(
          JSON.stringify({
            type: 'standard__recordPage',
            attributes: {
              recordId: id,
              objectApiName: this.objectApiName,
              actionName: 'view',
            },
          })
        ),
      };
    }

    pageRef.state.additionalParams = pageState.additionalParams;

    return pageRef;
  }

  getPageRefForClose(id, saveAndNew, pageState, data) {
    let pageRef = {
      type: 'standard__objectPage',
      attributes: {
        objectApiName: this.objectApiName,
        actionName: 'list',
      },
    };

    if (!data || !data.Deleted) {
      if (saveAndNew) {
        pageRef = this.getPageRefForSaveAndNew(id, pageState);
      } else if (pageState && pageState.inContextOfRef) {
        pageRef = pageState.inContextOfRef;
      } else if (VeevaUtils.validSfdcId(id)) {
        pageRef = {
          type: 'standard__recordPage',
          attributes: {
            recordId: id,
            objectApiName: this.objectApiName,
            actionName: 'view',
          },
        };
      } else if (this.record && this.record.retURL) {
        pageRef = {
          type: 'standard__webPage',
          attributes: {
            url: this.record.retURL,
          },
        };
      }
    }

    return pageRef;
  }

  getPageRefForDelete() {
    const pageRef = {
      type: 'standard__objectPage',
      attributes: {
        objectApiName: this.objectApiName,
        actionName: 'list',
      },
    };
    return pageRef;
  }

  getPageRefForUnlock() {
    // override in child implementations to navigate to different page after unlocking record
    return null;
  }

  useFlowNavAfterNew(saveAndNew, pageReferenceState) {// eslint-disable-line no-unused-vars
    // override in child implementations in order to use flow nav instead of pageRef
    return false;
  }

  useFlowNavAfterEdit(saveAndNew) {// eslint-disable-line no-unused-vars
    // override in child implementations in order to use flow nav instead of pageRef
    return false;
  }

  async getPicklistValues(field, recordTypeId) {
    const queryRecordTypeId = recordTypeId || this.record.recordTypeId;
    const picklistsMap = await this.uiApi.getPicklistValuesMap(queryRecordTypeId, this.objectApiName);
    return (picklistsMap && picklistsMap[field]) || { values: [] };
  }

  getProxiedService(service) {
    if (!service || typeof service !== 'object') {
      return service;
    }
    const functionHandler = {
      apply(target, thisArg, argumentsList) {
        const response = Reflect.apply(target, thisArg, argumentsList);
        if (response && typeof response === 'object' && typeof response.finally === 'function') {
          this.pageCtrl.page?.requests?.push(target.name);
          return response.finally(() => this.pageCtrl.page?.requests?.splice(this.pageCtrl.page.requests.indexOf(target.name), 1));
        }
        return response;
      },
      pageCtrl: this,
    };
    const handler = {
      get(target, prop) {
        if (typeof target[prop] === 'function') {
          return new Proxy(target[prop], functionHandler);
        }
        return Reflect.get(target, prop);
      },
    };
    return new Proxy(service, handler);
  }

  async performPreSaveConfirmationLogic() {
    return {
      showConfirmationModal: false,
      content: null
    }
  }
}