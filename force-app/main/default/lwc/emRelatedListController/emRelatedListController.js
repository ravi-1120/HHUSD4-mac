/* eslint-disable no-param-reassign */
import EmPageReference from 'c/emPageReference';
import VeevaRelatedListController from 'c/veevaRelatedListController';
import VeevaConstant from 'c/veevaConstant';
import { createMessageContext, publish } from 'lightning/messageService';
import eventsManagementChannel from '@salesforce/messageChannel/Events_Management_Channel_vod__c';
import { getKeyProps, getLayoutKeyToRecordIds, getLayout, createBaseApiFormattedError, createErrorObjectFromFieldErrors, getPleErrorType } from './saveUtils';

const VEEVA_RECORD_TYPE_SELECTOR_FLOW = 'VeevaRecordTypeSelectorFlow';
const VEEVA_EDIT_FLOW = 'VeevaEditRecordFlow';

export default class EmRelatedListController extends VeevaRelatedListController {
  rtToActionsMap = {};
  msgMap = {
    noAllowedToEdit: 'You do not have permission to edit this record.',
    readonlyPleField: 'You do not have permission to edit these fields: {0}',
    requiredPleField: 'The following fields are required: {0}',
  };

  constructor(meta, pageCtrl) {
    super(meta, pageCtrl);
    this.loadVeevaMessages();
  }

  get meta() {
    return this._meta;
  }

  set meta(value) {
    this._meta = value;
    this.rtToActionsMap = {};
  }

  get allowInlineEdit() {
    return true;
  }

  async loadVeevaMessages() {
    this.msgMap = await this.pageCtrl.messageSvc
      .createMessageRequest()
      .addRequest('NOT_ALLOWED_TO_EDIT', 'Common', this.msgMap.noAllowedToEdit, 'noAllowedToEdit')
      .addRequest('RELATED_LIST_PLE_FIELD_ERROR', 'EVENT_MANAGEMENT', this.msgMap.readonlyPleField, 'readonlyPleField')
      .addRequest('RELATED_LIST_PLE_REQUIRED_FIELD', 'EVENT_MANAGEMENT', this.msgMap.requiredPleField, 'requiredPleField')
      .sendRequest();
  }

  async getRowActions(row, doneCallback) {
    let { actions } = row;
    try {
      if (!actions) {
        if (this.rtToActionsMap && row.RecordTypeId in this.rtToActionsMap) {
          actions = this.rtToActionsMap[row.RecordTypeId];
        } else {
          actions = await this.getDropdownButtons(row, this.pageCtrl);
        }
        row.actions = actions;
      }
    } finally {
      doneCallback(actions);
    }
  }

  async getDropdownButtons(row, pageCtrl) {
    const actions = [];
    const { eventStatus, countryAlpha2Code, eventConfigId } = await pageCtrl.getPleParams();
    const response = await pageCtrl.emPageLayoutEngineSvc.getEventLayoutButtons(
      await pageCtrl.getEventId(),
      row.objectApiName || this.meta.objectApiName,
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

    this.rtToActionsMap[row.RecordTypeId] = actions;
    return actions;
  }

  async getNoAction(pageCtrl) {
    const noActionsMessage = await pageCtrl.getMessageWithDefault('NO_ACTIONS', 'Common', 'No actions available');
    return { label: noActionsMessage, name: 'noActions', disabled: true };
  }

  getEmDefaultFieldValues() {
    const defVals = {};
    if (this.pageCtrl?.record?.fields?.Event_vod__r?.value?.id) {
      defVals.Event_vod__c = {
        value: this.pageCtrl.record.fields.Event_vod__r.value.id,
        displayValue: this.pageCtrl.record.fields.Event_vod__r.displayValue,
      };
    } else if (this.pageCtrl?.record?.fields?.Event_vod__c) {
      defVals.Event_vod__c = this.pageCtrl.record.fields.Event_vod__c;
    }
    return defVals;
  }

  async getInContextOfRefForNew() {
    const inContextOfRef = await super.getInContextOfRefForNew();
    const defVals = this.getEmDefaultFieldValues();
    inContextOfRef.emDefaultFieldValues = EmPageReference.encodeEmDefaultFieldValues(defVals);
    inContextOfRef.pleParams = await this.pageCtrl.getPleParams();
    inContextOfRef.relationship = this.meta.relationship;
    return inContextOfRef;
  }

  async getInContextOfRefForEdit() {
    const inContextOfRef = await super.getInContextOfRefForNew();
    inContextOfRef.relationship = this.meta.relationship;
    return inContextOfRef;
  }

  async launchNewFlow(context) {
    const payload = {
      flowName: VEEVA_RECORD_TYPE_SELECTOR_FLOW,
      flowVariables: this.getFlowVariables(context),
    };
    publish(createMessageContext(), eventsManagementChannel, payload);
  }

  async launchEditFlow(row) {
    const context = await this.getInContextOfRefForEdit();
    const payload = {
      flowName: VEEVA_EDIT_FLOW,
      flowVariables: this.getFlowVariables(context, row),
    };
    publish(createMessageContext(), eventsManagementChannel, payload);
  }

  getFlowVariables(context, row) {
    const flowVars = [
      {
        name: 'objectApiName',
        value: row?.objectApiName || this.objectDescribe.apiName,
        type: 'String',
      },
      {
        name: 'flowContext',
        value: JSON.stringify(context),
        type: 'String',
      },
    ];

    if (row) {
      flowVars.push({
        name: 'recordId',
        value: row.Id,
        type: 'String',
      });
    } else {
      flowVars.push({
        name: 'skipRecordTypeSelector',
        value: false,
        type: 'Boolean',
      });
    }
    return flowVars;
  }

  /**
   * Saves the draft values for the provided related-list records.
   * Performs permission and layout validation against PLE config to filter
   * offending records.
   * 
   * @param {Object[]} recordsToSave 
   * @returns Object containing collections of saved and failed records
   */
  async save(recordsToSave) {
    const layoutKeyToRecordIds = await getLayoutKeyToRecordIds(recordsToSave, this.pageCtrl, this.objectDescribe.apiName);

    // Get mappings of record ID to layout data (buttons, fields) and error information
    const idToLayoutData = await this.getRecordIdToLayoutData(this.pageCtrl, this.objectDescribe.apiName, layoutKeyToRecordIds);
    const idToLayoutErrors = this.validateDraftFieldsAgainstPageLayout(recordsToSave, idToLayoutData);

    // Exclude record IDs with errors found during layout validation
    const idsToExcludeFromSave = new Set(Object.keys(idToLayoutErrors));
    
    // Filter down records based on violations of object-level and layout-field-level permissions
    const toSave = recordsToSave.filter(record => !idsToExcludeFromSave.has(record.Id));
    const { savedRecords = [], failedRecords = [] } = await super.save(toSave);

    // In addition to Salesforce-based errors from the above save operation, add errors from the pre-save validation step
    for (const excludedId of idsToExcludeFromSave) {
      failedRecords.push(idToLayoutErrors[excludedId]);
    }

    return { savedRecords, failedRecords };
  }

  /**
   * Constructs a mapping of layout key to corresponding layout request that, when resolved,
   * will contain layout data information for that layout configuration.
   * @param {Object} pageCtrl Page controller providing access to EM page layout engine service
   * @param {String} objectApiName API name for related-list object
   * @param {Object} layoutKeyToRecordIds Mapping of layout key to record IDs that match in their PLE params
   * @returns Mapping of layout key to corresponding layout promise
   */
  getLayoutKeyToRequest(pageCtrl, objectApiName, layoutKeyToRecordIds) {
    const layoutKeyToRequest = {};

    Object.keys(layoutKeyToRecordIds).forEach(key => {
      const { recordTypeId, eventId, pleParams } = getKeyProps(key);
      const getLayoutPromise = getLayout(pageCtrl.emPageLayoutEngineSvc, objectApiName, VeevaConstant.EDIT, recordTypeId, eventId, pleParams);
      layoutKeyToRequest[key] = getLayoutPromise;
    });

    return layoutKeyToRequest;
  };

  /**
   * Returns a mapping of record IDs to their corresponding layout errors based on object
   * and field-level permissions defined by the PLE layout.
   * @param {Object[]} records Records being saved
   * @param {Object} idToLayoutData Mapping of record ID to layout data
   * @returns Mapping of record IDs to layout error collections
   */
  validateDraftFieldsAgainstPageLayout(records, idToLayoutData) {
    const idToLayoutErrors = {};

    records.forEach(record => {
      const recordId = record.Id;
      const layout = idToLayoutData[recordId];

      // Check if the record supported by the layout even has Edit as an available object-level action
      const hasEditButton = layout.layoutButtons?.some(button => button.name === 'Edit');
      if (!hasEditButton) {
        idToLayoutErrors[recordId] = createBaseApiFormattedError(this.objectDescribe.apiName, recordId, [{ fields: [], message: this.msgMap.noAllowedToEdit }]);
      } else {
        // Evaluate editable/required criteria of the layout fields
        const { layoutFields } = layout;
        const failedFieldErrors = [];
        Object.keys(record).forEach(field => {
          const errorType = getPleErrorType(field, layoutFields, record);
          if (errorType) {
            failedFieldErrors.push({ field, errorType });
          }
        });

        if (failedFieldErrors.length) {
          idToLayoutErrors[recordId] = createErrorObjectFromFieldErrors(recordId, failedFieldErrors, this.msgMap, this.objectDescribe);
        }
      }
    });

    return idToLayoutErrors;
  }

  /**
   * Returns a mapping of record IDs to layout-data objects, containing
   * information such as available actions (Edit, Delete) and field-level
   * properties around requiredness and editability.
   * @param {Object} pageCtrl 
   * @param {String} objectApiName 
   * @param {String[]} recordIds 
   * @param {Object} idToLayoutKey 
   * @returns Mapping of related-list-record id to its layout button and field data
   */
  async getRecordIdToLayoutData(pageCtrl, objectApiName, layoutKeyToRecordIds) {
    const idToLayoutData = {};
    const layoutKeyToRequest = this.getLayoutKeyToRequest(pageCtrl, objectApiName, layoutKeyToRecordIds);
    await Promise.all(Object.entries(layoutKeyToRequest).map(([id, promise]) =>
      promise.then(data => ({ id, data }))
    )).then(resolvedValues => {
      resolvedValues.forEach(({ id: layoutKey, data: layoutData }) => {
        let layout;
        if (layoutData.length) {
          layout = this.flattenLayoutData(layoutData[0]);
        } else {
          layout = this.flattenLayoutData(layoutData);
        }

        const recordIdsForKey = layoutKeyToRecordIds[layoutKey];
        recordIdsForKey.forEach(recordId => {
          idToLayoutData[recordId] = layout;
        });
      });
    });

    return idToLayoutData;
  };

  flattenLayoutData(layout) {
    const layoutButtons = layout.buttons;
    const layoutFields = {};
    if (layout.sections) {
      for (const section of layout.sections) {
        for (const row of section.layoutRows) {
          for (const item of row.layoutItems) {
            layoutFields[item.field] = item;
          }
        }
      }
    }

    return { layoutButtons, layoutFields };
  }

  /**
   * Overrides parent method to check edit permission from PLE
   * @param {Object} column
   * @returns {boolean}
   */
  checkEditPermission(column) {
    return !column.readOnly;
  }
}