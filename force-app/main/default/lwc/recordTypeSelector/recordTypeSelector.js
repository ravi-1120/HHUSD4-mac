import { LightningElement, api, track, wire } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getService, SERVICES } from 'c/veevaServiceFactory';
import { getPageController } from 'c/veevaPageControllerFactory';
import { FlowNavigationNextEvent } from 'lightning/flowSupport';
import VeevaUtils from 'c/veevaUtils';

export default class RecordTypeSelector extends LightningElement {
  @api objectApiName;
  @api selectedRtId;
  @api exitEarly;

  @track labelCancel;
  @track labelNext;
  @track labelSelectRecordType;
  @track insufficientPrivilegesMessage;
  @track labelObject;
  @track newObjectTemplate;
  @track isCreateable;

  @track recordTypeInfos = [];

  constructor() {
    super();
    this.initComponent();
  }

  async initComponent() {
    this._uiApi = getPageController('userInterfaceSvc');
    this._uiApi.requests = [];

    const messageService = getService(SERVICES.MESSAGE);
    const messageRequest = messageService.createMessageRequest();

    [
      { key: 'CANCEL', category: 'Common', defaultMessage: 'Cancel', label: 'labelCancel' },
      { key: 'NEXT_STEP', category: 'CallReport', defaultMessage: 'Next', label: 'labelNext' },
      { key: 'SELECT_RECORDTYPE', category: 'Common', defaultMessage: 'Select a record type', label: 'labelSelectRecordType' },
      { key: 'NEW', category: 'Common', defaultMessage: 'New', label: 'newObjectTemplate' },
      {
        key: 'INSUFFICIENT_PRIVILEGES',
        category: 'Common',
        defaultMessage:
          'Insufficient Privileges: You do not have the level of access necessary to perform the operation you requested. Please contact the owner of the record or your administrator if access is necessary.',
        label: 'insufficientPrivilegesMessage',
      },
    ].forEach(({key, category, defaultMessage, label}) => {
      messageRequest.addRequest(key, category, defaultMessage, label);
    });

    const messageMap = await messageRequest.sendRequest();

    Object.entries(messageMap).forEach(([label, message]) => {
      this[label] = message;
    });
  }

  get titleNewObject() {
    return `${this.newObjectTemplate} ${this.labelObject}` || '';
  }

  @wire(getObjectInfo, { objectApiName: '$objectApiName' })
  wiredObjectInfo({ error, data }) {
    if (data) {
      this.isCreateable = data.createable;
      if (this.isCreateable) {
        this.labelObject = data.label;
        const availableTypes = data.recordTypeInfos ? VeevaUtils.getAvailableRecordTypes(data.recordTypeInfos) : [];
        if (availableTypes.length === 1) {
          this.selectedRtId = availableTypes[0].value;
          this.goToNext();
        } else {
          this.setRecordTypeInfos(availableTypes);
        }
      }
    }
    if (error) {
      if (error?.body?.errorCode === 'INSUFFICIENT_ACCESS') {
        this.isCreateable = false;
      }
    }
  }

  async setRecordTypeInfos(recordTypes) {
    if (recordTypes && recordTypes.length > 1) {
      const rtIds = recordTypes.map(rt => rt.value);
      const records = await this._uiApi.getBatchRecords(rtIds, ['RecordType.Description'], true);
      const idToDesc = records.reduce((tempMap, rtRecord) => {
        if (rtRecord.fields && rtRecord.fields.Description) {
          tempMap[rtRecord.id] = rtRecord.fields.Description.displayValue;
        }
        return tempMap;
      }, {});
      recordTypes.forEach(rt => {
        rt.description = idToDesc[rt.value];
      });
    }
    let defaultSelectedIndex = recordTypes.findIndex(typeInfo => typeInfo.defaultType);
    // Only occurs in the case record types are only assigned via permission sets
    if (defaultSelectedIndex === -1) {
      defaultSelectedIndex = 0;
    }
    const defaultSelected = recordTypes[defaultSelectedIndex];

    if (defaultSelected) {
      defaultSelected.checked = true;
      this.selectedRtId = defaultSelected.value;
      recordTypes.splice(defaultSelectedIndex, 1);
      recordTypes.unshift(defaultSelected);
    }
    this.recordTypeInfos = recordTypes;
  }

  handleRecordTypeChange(event) {
    const selectedId = event.target.value;
    this.selectedRtId = selectedId;
    this.recordTypeInfos.forEach(info => {
      info.checked = info.value === selectedId;
    });
  }

  goToNext() {
    this.dispatchEvent(new FlowNavigationNextEvent());
  }

  finishFlow() {
    this.exitEarly = true;
    this.goToNext();
  }

  get showRecordTypeSelector() {
    return this.isCreateable && this.recordTypeInfos.length > 0;
  }

  get isNotCreateable() {
    return this.isCreateable === false;
  }
}