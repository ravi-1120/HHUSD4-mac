import EmController from 'c/emController';
import PicklistController from "c/picklistController";
import { getService, SERVICES } from 'c/veevaServiceFactory';
import { VeevaMessageRequest } from 'c/veevaMessageService';
import getWalkInAttendeeStatuses from '@salesforce/apex/VeevaEmAttendeeReconciliation.getWalkInAttendeeStatuses';

import { getFieldValue } from 'lightning/uiRecordApi';

import STATUS from '@salesforce/schema/EM_Attendee_vod__c.Status_vod__c';
import MEAL_OPT_IN from '@salesforce/schema/EM_Attendee_vod__c.Meal_Opt_In_vod__c';
import WALK_IN_TYPE from '@salesforce/schema/EM_Attendee_vod__c.Walk_In_Type_vod__c';

import EVENT_CONFIG from '@salesforce/schema/EM_Event_vod__c.Event_Configuration_vod__c';
import COUNTRY from '@salesforce/schema/EM_Event_vod__c.Country_vod__c';
import WALK_IN_FIELDS from '@salesforce/schema/EM_Event_vod__c.Walk_In_Fields_vod__c';
import PRESCRIBER_WALK_IN_FIELDS from '@salesforce/schema/EM_Event_vod__c.Prescriber_Walk_In_Fields_vod__c';
import NON_PRESCRIBER_WALK_IN_FIELDS from '@salesforce/schema/EM_Event_vod__c.Non_Prescriber_Walk_In_Fields_vod__c';
import OTHER_WALK_IN_FIELDS from '@salesforce/schema/EM_Event_vod__c.Other_Walk_In_Fields_vod__c';

const PRESCRIBER_VOD = 'Prescriber_vod';
const NON_PRESCRIBER_VOD = 'Non_Prescriber_vod';
const OTHER_VOD = 'Other_vod';
const WALK_IN_TYPE_TO_FIELD_MAP = {
    [PRESCRIBER_VOD]: PRESCRIBER_WALK_IN_FIELDS.fieldApiName,
    [NON_PRESCRIBER_VOD]: NON_PRESCRIBER_WALK_IN_FIELDS.fieldApiName,
    [OTHER_VOD]: OTHER_WALK_IN_FIELDS.fieldApiName,
}
const MESSAGES = [
    { key: 'PAGE_LAYOUT_TITLE', category: 'Common', defaultMessage: 'Details' },
    { key: 'MEAL_OPT_IN', category: 'EVENT_MANAGEMENT', defaultMessage: 'Opt In' },
    { key: 'MEAL_OPT_OUT', category: 'EVENT_MANAGEMENT', defaultMessage: 'Opt Out' },
    { key: 'NEW_WALK_IN', category: 'EVENT_MANAGEMENT', defaultMessage: 'New Walk-In' }
];

const DEFAULT_FIELDS_SET = [MEAL_OPT_IN.fieldApiName, STATUS.fieldApiName];
export default class EmNewWalkInPageController extends EmController {

    msgMap;
    attendeeStatuses;
    eventRecord;
    allWalkInFields;
    walkInFieldLayouts = {};

    constructor(allWalkInFields, eventRecord) {
        const dataSvc = getService(SERVICES.DATA);
        const userInterfaceSvc = getService(SERVICES.UI_API);
        const messageSvc = getService(SERVICES.MESSAGE);
        const metaStore = getService(SERVICES.META);
        super(dataSvc, userInterfaceSvc, messageSvc, metaStore);

        this.eventRecord = eventRecord;
        this.allWalkInFields = allWalkInFields;
        this.getAttendeeStatuses();
        this.getNewWalkInMessageMap(); 
    }

    get walkInTypeEnabled() {
        return Boolean(this.walkInFieldLayouts[PRESCRIBER_WALK_IN_FIELDS.fieldApiName]) || 
            Boolean(this.walkInFieldLayouts[NON_PRESCRIBER_WALK_IN_FIELDS.fieldApiName]) || 
            Boolean(this.walkInFieldLayouts[OTHER_WALK_IN_FIELDS.fieldApiName]);
    }

    get walkInTypeValue() {
        return this.record?.rawValue(WALK_IN_TYPE.fieldApiName);
    }

    async getAttendeeStatuses() {
        if (!this.attendeeStatuses) {
            const eventConfigId = getFieldValue(this.eventRecord, EVENT_CONFIG);
            const eventCountryId = getFieldValue(this.eventRecord, COUNTRY);
            this.attendeeStatuses = await getWalkInAttendeeStatuses({ eventCountryId, eventConfigId });
        }
        return this.attendeeStatuses;
    }

    async getNewWalkInMessageMap() {
        if (!this.msgMap) {
            const vmr = new VeevaMessageRequest();
            MESSAGES.forEach(({key, category, defaultMessage}) => vmr.addRequest(key, category, defaultMessage, `${key};;${category}`));
            this.msgMap = {};
            try {
                this.msgMap = await this.messageSvc.getMessageMap(vmr);
            } catch (e) {
                MESSAGES.forEach(({key, category, defaultMessage}) => {
                    this.msgMap[`${key};;${category}`] = defaultMessage;
                });
            }
        }
        return this.msgMap;
    }

    async updateNewPageTitle() {
        const msgMap = await this.getNewWalkInMessageMap();
        this.page.title = msgMap['NEW_WALK_IN;;EVENT_MANAGEMENT'];
    }

    async getModalButtons() {
        const buttons = await super.getModalButtons();
        if (this.canCreate) {
            const saveAndNew = await this.createSaveAndNewButton();
            buttons.splice(1, 0, saveAndNew);
        }
        return buttons;
    }

    initItemController(meta, record) {
        let ctrl = super.initItemController(meta, record);
        const fieldName = meta.field;
        if (fieldName === WALK_IN_TYPE.fieldApiName) {
            ctrl.excludeNone = true;
        } else if (fieldName === MEAL_OPT_IN.fieldApiName) {
            ctrl = new PicklistController(meta, this, this.objectInfo.getFieldInfo(meta.field), record);
        }
        return ctrl;
    }

    async getPicklistValues(field, recordTypeId) {
        const picklistValues = await super.getPicklistValues(field, recordTypeId);
        if (field === WALK_IN_TYPE.fieldApiName) {
            picklistValues.values = picklistValues.values.filter(({ value }) => this.walkInFieldLayouts[WALK_IN_TYPE_TO_FIELD_MAP[value]]);
        } else if (field === MEAL_OPT_IN.fieldApiName) {
            const msgMap = await this.getNewWalkInMessageMap();
            picklistValues.values = ['true', 'false'].map((value, key) => ({
                key,
                value,
                label: value === 'true' ? msgMap['MEAL_OPT_IN;;EVENT_MANAGEMENT'] : msgMap['MEAL_OPT_OUT;;EVENT_MANAGEMENT']
            }));
        } else if (field === STATUS.fieldApiName) {
            const statuses = await this.getAttendeeStatuses();
            if (statuses?.length > 0) {
                picklistValues.values = picklistValues.values.filter(({ value }) => statuses.includes(value) );
            }
        }
        return picklistValues;
    }

    async initWalkInType() {
        await this.getWalkInFieldsLayouts();
        if (this.walkInTypeEnabled && !this.walkInTypeValue) {
            this.record.setFieldValue(WALK_IN_TYPE.fieldApiName, PRESCRIBER_VOD); // Set default to Prescriber if not populated
        }
    }

    async initRecordCreateBase(pageRef) {
        await super.initRecordCreateBase(pageRef);
        await this.initWalkInType();
    }

    async initPageLayout() {
        const walkInFieldLayouts = await this.getWalkInFieldsLayouts();
        let layout = walkInFieldLayouts[WALK_IN_FIELDS.fieldApiName];
        if (this.walkInTypeEnabled) {
            const walkInType = this.walkInTypeValue;
            layout = walkInFieldLayouts[WALK_IN_TYPE_TO_FIELD_MAP[walkInType]];
        }
        this.page.layout = layout;
        this.setButtons();
    }

    async getWalkInFieldsLayouts() {
        if (Object.entries(this.walkInFieldLayouts).length === 0) {
            const msgMap = await this.getNewWalkInMessageMap();
            this.walkInFieldLayouts[WALK_IN_FIELDS.fieldApiName] = this.convertWalkInFieldsToLayout(this.allWalkInFields[WALK_IN_FIELDS.fieldApiName], false, msgMap);
            this.walkInFieldLayouts[PRESCRIBER_WALK_IN_FIELDS.fieldApiName] = this.convertWalkInFieldsToLayout(this.allWalkInFields[PRESCRIBER_WALK_IN_FIELDS.fieldApiName], true, msgMap);
            this.walkInFieldLayouts[NON_PRESCRIBER_WALK_IN_FIELDS.fieldApiName] = this.convertWalkInFieldsToLayout(this.allWalkInFields[NON_PRESCRIBER_WALK_IN_FIELDS.fieldApiName], true, msgMap);
            this.walkInFieldLayouts[OTHER_WALK_IN_FIELDS.fieldApiName] = this.convertWalkInFieldsToLayout(this.allWalkInFields[OTHER_WALK_IN_FIELDS.fieldApiName], true, msgMap);
        }
        return this.walkInFieldLayouts;
    }

    convertWalkInFieldsToLayout(walkInFields, isWalkInTypeField, msgMap) {
        if (!walkInFields || (walkInFields && walkInFields.length === 0)) {
            return null;
        }
        const layoutRows = [];
        let layoutItems = [];
        const fields = walkInFields.filter(({ apiName }) => WALK_IN_TYPE.fieldApiName !== apiName && !DEFAULT_FIELDS_SET.includes(apiName));
        DEFAULT_FIELDS_SET.forEach(apiName => {
            const fieldInfo = this.objectInfo.getFieldInfo(apiName);
            if (fieldInfo?.updateable) {
                fields.push({
                    apiName,
                    label: fieldInfo.label,
                    required: true,
                });
            }
        });
        if (isWalkInTypeField) {
            layoutRows.unshift({
                key: 0,
                layoutItems: [
                    this.createLayoutItem(0, WALK_IN_TYPE.fieldApiName, this.objectInfo.getFieldInfo(WALK_IN_TYPE.fieldApiName).label),
                    this.createLayoutItem(1, null, null, false, false)
                ]
            });
        }
        fields.forEach((field, index, array) => {
            const key = index % 2;
            const item = this.createLayoutItem(key, field.apiName, field.label, field.required);
            layoutItems.push(item);
            if (layoutItems.length === 2 || index === array.length-1) {
                if (layoutItems.length === 1) {
                    layoutItems.push(this.createLayoutItem(1, null, null, false, false));
                }
                layoutRows.push({
                    key: layoutRows.length,
                    layoutItems
                });
                layoutItems = [];
            }
        });
        const layout = {
            sections: [
                {
                    key: 0,
                    heading: msgMap['PAGE_LAYOUT_TITLE;;Common'],
                    layoutRows,
                }
            ]
        };
        return layout;
    }

    createLayoutItem(key, field, label, required=true, editable=true) {
        const item = {
            key,
            editable,
            editableForNew: editable,
            editableForUpdate: editable,
            field,
            label,
            required,
            layoutComponents: []
        };
        if (field) {
            item.layoutComponents.push({
                    componentType: 'Field',
                    apiName: field
                });
        }
        return item;
    }

}