import { LightningElement, api, track, wire } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getRecord } from 'lightning/uiRecordApi';
import EmPageReference from 'c/emPageReference';
import { getService, SERVICES } from 'c/veevaServiceFactory';
import VeevaToastEvent from 'c/veevaToastEvent';
import getAttendeeRecordType from '@salesforce/apex/EmAttendeeSelection.getAttendeeRecordType';

import EM_ATTENDEE from '@salesforce/schema/EM_Attendee_vod__c';
import EVENT_LOOKUP from '@salesforce/schema/EM_Attendee_vod__c.Event_vod__c';
import WALK_IN_STATUS from '@salesforce/schema/EM_Attendee_vod__c.Walk_In_Status_vod__c';
import WALK_IN_TYPE from '@salesforce/schema/EM_Attendee_vod__c.Walk_In_Type_vod__c';
import FIRST_NAME from '@salesforce/schema/EM_Attendee_vod__c.First_Name_vod__c';
import LAST_NAME from '@salesforce/schema/EM_Attendee_vod__c.Last_Name_vod__c';
import NAME from '@salesforce/schema/EM_Event_vod__c.Name';
import RECORD_TYPE_ID from '@salesforce/schema/EM_Event_vod__c.RecordTypeId';
import EVENT_CONFIG from '@salesforce/schema/EM_Event_vod__c.Event_Configuration_vod__c';
import COUNTRY from '@salesforce/schema/EM_Event_vod__c.Country_vod__c';

import EmNewWalkInPageController from './emNewWalkInPageController';

const NEEDS_RECONCILIATION_VOD = 'Needs_Reconciliation_vod';
export default class EmNewWalkInModal extends LightningElement {

    @api eventId;
    @api walkInFields;
    ctrl;
    objectInfo;
    @track page = {
        requests: [],
        action: 'New',
        recordUpdateFlag: true,
    };

    @wire(getObjectInfo, { objectApiName: EM_ATTENDEE })
    wireObjectInfo({data, error}) {
        if (data) {
            this.objectInfo = data;
        }
        if (error) {
            this.handleError(error);
        }
    }

    @wire(getRecord, { recordId: '$eventId', fields: [ NAME, RECORD_TYPE_ID, EVENT_CONFIG, COUNTRY ]})
    wireGetRecord({data, error}) {
        if (data) {
            this.eventRecord = data;
            this.init();
        }
        if (error) {
            this.handleError(error);
        }
    }

    connectedCallback() {
        this.messageService = getService(SERVICES.MESSAGE);
    }

    async init() {
        this.ctrl = new EmNewWalkInPageController(this.walkInFields, this.eventRecord);
        this.ctrl.objectInfo = this.objectInfo;
        this.ctrl.page = this.page;
        await this.resetRecord();
    }

    async resetRecord(walkInType) {
        const recordTypeId = await this.getAttendeeRecordType();
        const emDefaultFieldValues = {
            [EVENT_LOOKUP.fieldApiName]: {
                displayValue: this.eventRecord.fields.Name.value,
                value: this.eventRecord.id
            },
            [WALK_IN_STATUS.fieldApiName]: {
                value: NEEDS_RECONCILIATION_VOD
            }
        };
        if (walkInType) {
            emDefaultFieldValues[WALK_IN_TYPE.fieldApiName] = {
                value: walkInType
            };
        }
        const pageRef = {
            state: { 
                recordTypeId,
                inContextOfRef: {
                    attributes: {
                        recordId: this.eventRecord.id
                    },
                    emDefaultFieldValues: EmPageReference.encodeEmDefaultFieldValues(emDefaultFieldValues),
                    relationship: 'Event_vod__r'
                }
            },
            attributes: {
                objectApiName: EM_ATTENDEE.objectApiName
            }
        };
        try {
            await this.ctrl.initRecordCreate(pageRef);
            this.ctrl.track(WALK_IN_TYPE.fieldApiName, this, 'updateLayout');
        } catch (e) {
            this.handleError(e);
        }
    }

    updateLayout(value) {
        this.template.querySelector('c-veeva-modal-page')?.clearPageError();
        this.page.layout = {}; // required for clearing state on field controllers
        this.resetRecord(value)
            .then(() => {
                this.page.recordUpdateFlag = !this.page.recordUpdateFlag
            });
    }

    async getAttendeeRecordType() {
        const eventRecordTypeId = this.eventRecord.recordTypeId;
        if (!this.attendeeRecordTypeId) {
            const attendeeRecordType = await getAttendeeRecordType({ eventRecordTypeId });
            this.attendeeRecordTypeId = attendeeRecordType ?? this.objectInfo.defaultRecordTypeId;
        }
        return this.attendeeRecordTypeId;
    }

    async handleClose(event) {
        const { detail } = event;
        let closeEvent = new CustomEvent('close', { detail });
        if (detail) { // save action
            const firstName = this.ctrl.record.rawValue(FIRST_NAME.fieldApiName);
            const lastName = this.ctrl.record.rawValue(LAST_NAME.fieldApiName);
            const name = `${lastName}, ${firstName}`;
            const msg = await this.getAttendeeAddedMessage(name);
            this.dispatchEvent(VeevaToastEvent.successMessage(msg));
            if (detail.saveAndNew) {
                this.updateLayout();
                closeEvent = null;
            }
        }
        if (closeEvent) {
            this.dispatchEvent(closeEvent);
        }
    }

    async getAttendeeAddedMessage(name) {
        if (!this.attendeeAddedMessage) {
            this.attendeeAddedMessage = await this.messageService.getMessageWithDefault('ATTENDEE_ADDED', 'EVENT_MANAGEMENT', 'Last Attendee Added: {0}');
        }
        return this.attendeeAddedMessage.replace('{0}', name);
    }

    handleError(error) {
        this.dispatchEvent(VeevaToastEvent.error(error));
    }
}