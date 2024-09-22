import { createMessageContext, publish } from 'lightning/messageService';
import EmRelatedListController from 'c/emRelatedListController';
import VeevaConstant from 'c/veevaConstant';
import eventsManagementChannel from '@salesforce/messageChannel/Events_Management_Channel_vod__c';

const EVENT_FIELDS_TO_COPY = ['End_Time_vod__c', 'Start_Time_vod__c'];
const LOCAL_DATE_TIME_FIELDS_TO_COPY = [
  'End_Date_vod__c',
  'End_Time_Local_vod__c',
  'Start_Date_vod__c',
  'Start_Time_Local_vod__c',
  'Time_Zone_vod__c',
];

export default class EmEventRelatedListController extends EmRelatedListController {
  rowIdToActionsMap = {};
  
  set meta(value) {
    this._meta = value;
    this.rowIdToActionsMap = {};
  }

  get meta() {
    return this._meta;
  }

  async getRowActions(row, doneCallback) {
    let actions = [];
    try {
      if (row.Id in this.rowIdToActionsMap) {
        actions = this.rowIdToActionsMap[row.Id];
      } else {
        actions = await this.getDropdownButtons(row, this.pageCtrl);
      }
      row.actions = actions;
    } finally {
      doneCallback(actions);
    }
  }

  async getDropdownButtons(row, pageCtrl) {
    const actions = [];
    const [rowRecord, parentEventId, parentEventParams] = await Promise.all([
      this.getRowRecord(row.Id, pageCtrl),
      pageCtrl.getEventId(),
      pageCtrl.getPleParams()
    ]);
    const rowEventParams = this.extractEventParams(rowRecord);
    const { eventStatus, countryAlpha2Code, eventConfigId } = 
      this.hasRequiredEventParams(rowEventParams) ? rowEventParams : parentEventParams;

    const response = await pageCtrl.emPageLayoutEngineSvc.getEventLayoutButtons(
      rowRecord ? row.Id : parentEventId,
      this.meta.objectApiName,
      row.RecordTypeId,
      eventStatus,
      countryAlpha2Code,
      eventConfigId
    );

    if (response?.data?.buttons) {
      Object.values(response.data.buttons).forEach(value => {
        if (row.isUpdateable && value.name === VeevaConstant.EDIT) {
          actions.push({ label: value.label, name: 'edit' });
        }
        if (row.isDeletable && value.name === VeevaConstant.DELETE) {
          actions.push({ label: value.label, name: 'delete' });
        }
      });

      if (actions.length === 0) {
        actions.push(await this.getNoAction(pageCtrl));
      }
    }

    this.rowIdToActionsMap[row.Id] = actions;
    return actions;
  }

  async getRowRecord(recordId, pageCtrl) {
    const EVENT_STATUS_FIELD = 'EM_Event_vod__c.Status_vod__c';
    const EVENT_ALPHA_COUNTRY_CODE = 'EM_Event_vod__c.Country_vod__r.Alpha_2_Code_vod__c';
    const EVENT_CONFIG_ID = 'EM_Event_vod__c.Event_Configuration_vod__c';
    return pageCtrl.uiApi.getRecord(recordId, [EVENT_STATUS_FIELD, EVENT_ALPHA_COUNTRY_CODE, EVENT_CONFIG_ID]);
  }

  hasRequiredEventParams(record) {
    return record.eventStatus && record.countryAlpha2Code && record.eventConfigId;
  }

  extractEventParams(record) {
    return {
      eventStatus: record?.fields?.Status_vod__c?.value,
      countryAlpha2Code: record?.fields?.Country_vod__r?.value?.fields?.Alpha_2_Code_vod__c?.value,
      eventConfigId: record?.fields?.Event_Configuration_vod__c?.value
    };
  }
  
  // eslint-disable-next-line no-unused-vars
  async launchNewFlow(context) {
    const payload = {
      flowName: 'VeevaNewChildEventFlow',
      flowVariables: [
        {
          name: 'parentEventId',
          value: this.pageCtrl.recordId,
          type: 'String',
        },
        {
          name: 'defaultFieldValues',
          value: JSON.stringify(this.getDefaultFieldValues()),
          type: 'String',
        },
      ],
    };
    publish(createMessageContext(), eventsManagementChannel, payload);
  }

  getDefaultFieldValues() {
    const defaultFieldValues = { Parent_Event_vod__c: this.pageCtrl.recordId };
    let fieldsToCopy = EVENT_FIELDS_TO_COPY;
    if (this.pageCtrl.isLocalDateTimeActive()) {
      fieldsToCopy = [...EVENT_FIELDS_TO_COPY, ...LOCAL_DATE_TIME_FIELDS_TO_COPY];
    }
    for (const eventField of fieldsToCopy) {
      const fieldValue = this.pageCtrl.record.rawValue(eventField);
      if (fieldValue) {
        defaultFieldValues[eventField] = fieldValue;
      }
    }
    return defaultFieldValues;
  }
}