import { api, track, wire, LightningElement } from 'lwc';
import { getObjectInfos } from 'lightning/uiObjectInfoApi';
import EM_EVENT from '@salesforce/schema/EM_Event_vod__c';
import EM_SPEAKER_QUALIFICATION from '@salesforce/schema/EM_Speaker_Qualification_vod__c';
import END_DATE from '@salesforce/schema/EM_Speaker_Qualification_vod__c.End_Date_vod__c';
import EM_EVENT_SPEAKER from '@salesforce/schema/EM_Event_Speaker_vod__c';
import STATUS from '@salesforce/schema/EM_Event_Speaker_vod__c.Status_vod__c';
import SPEAKER_IDENTIFIER from '@salesforce/schema/EM_Speaker_vod__c.Speaker_Identifier_vod__c';

const DEFAULT_ICON = 'custom:custom84';
export default class SpeakerSelectionDetailsPopover extends LightningElement {
    
    @wire(getObjectInfos, { objectApiNames: [ EM_EVENT, EM_SPEAKER_QUALIFICATION, EM_EVENT_SPEAKER ] })
    wireObjectInfo({error, data}) {
        if (data?.results) {
            for (const response of data.results) {
                if (response?.statusCode === 200) {
                    const objectInfo = response.result;
                    const objectApiName = objectInfo?.apiName
                    if (objectApiName === EM_EVENT.objectApiName) {
                        this.eventObjectLabel = objectInfo.label;
                    } else if (objectApiName === EM_SPEAKER_QUALIFICATION.objectApiName) {
                        this.speakerQualificationEndDateLabel = objectInfo.fields[END_DATE.fieldApiName]?.label;
                    } else if (objectApiName === EM_EVENT_SPEAKER.objectApiName) {
                        this.emEventSpeakerStatusLabel = objectInfo.fields[STATUS.fieldApiName]?.label;
                    }
                }
            }
        }
        if (error || data) {
            this.resolveObjectInfoLabels();
        }
    };

    @track requests = [];

    @api ctrl;
    @api set record(record) {
        this._record = record;
        this.requests.push(record.Id);
        this.init().then(() => {
            this.requests.splice(this.requests.indexOf(record.Id), 1);
        });
    }
    get record() {
        return this._record;
    }

    get id() {
        return this.record.Id;
    }

    get icon() {
        return this.ctrl?.pageCtrl?.icon || DEFAULT_ICON;
    }

    get loading() {
        return this.requests.length > 0;
    }

    get isChecked() {
        return this.record.checked;
    }

    get hideConfirmationButton() {
        return this.record.disabled || this.loading;
    }

    get title() {
        return this.record.Name;
    }

    get identifier() {
        return this.record[SPEAKER_IDENTIFIER.fieldApiName];
    }

    get confirmationLabel() {
        return this.isChecked ? this.removeLabel : this.addLabel;
    }

    // Defaults
    eventObjectLabel = 'Event';
    speakerQualificationEndDateLabel = 'End Date';
    emEventSpeakerStatusLabel = 'Status';
    
    addLabel;
    removeLabel;
    cancelLabel;
    servicesHeaderLabel;
    recentEventsHeaderLabel;
    trainingHeaderLabel;

    objectInfoLabels = new Promise(resolve => { this.resolveObjectInfoLabels = resolve; });

    serviceColumns = [
        {
            fieldName: 'name'
        },
        {
            fieldName: 'rate'
        }
    ]
    @track services = [];

    @track recentEventsColumns = [];
    @track recentEvents = [];

    @track trainingColumns = [];
    @track training = [];
    @track speakerFields = [];
    
    async init() {
        const [details] = await Promise.all([this.ctrl.getDetails(this.record), this.getMessages()]);
        this.speakerFields = details.fields;
        this.cv = details.cv;
        this.services = details.services;
        this.recentEvents = details.recentEvents;
        this.training = details.training;

        this.servicesHeaderLabel = this.servicesHeaderMsg?.replace('{0}', `(${this.services?.length})`);
        this.recentEventsHeaderLabel = this.recentEventsHeaderMsg?.replace('{0}', `(${this.recentEvents?.length})`);
        this.trainingHeaderLabel = this.trainingHeaderMsg?.replace('{0}', `(${this.training?.length})`);
    }

    async getMessages() {
        const [addLabel, removeLabel, cancelLabel, viewCvLabel, detailsHeaderMsg, servicesHeaderMsg, recentEventsHeaderMsg, trainingHeaderMsg, topicMsg, noRecordsLabel, eventCanceledMsg, startDateLabel, ownerLabel] = await Promise.all([
            { key: 'ADD_SPEAKER', category: 'EVENT_MANAGEMENT', defaultMessage: 'Add Speaker' },
            { key: 'REMOVE_SPEAKER', category: 'EVENT_MANAGEMENT', defaultMessage: 'Remove Speaker' },
            { key: 'CANCEL', category: 'Common', defaultMessage: 'Cancel'},
            { key: 'VIEW_CV', category: 'EVENT_MANAGEMENT', defaultMessage: 'View CV'},
            { key: 'PAGE_LAYOUT_TITLE', category: 'Common', defaultMessage: 'Details' },
            { key: 'SERVICES', category: 'EVENT_MANAGEMENT', defaultMessage: 'Services {0}'},
            { key: 'RECENT_EVENTS', category: 'EVENT_MANAGEMENT', defaultMessage: 'Recent Events {0}'},
            { key: 'TRAINING', category: 'EVENT_MANAGEMENT', defaultMessage: 'Training {0}'},
            { key: 'TOPIC', category: 'EVENT_MANAGEMENT', defaultMessage: 'Topic'},
            { key: 'NO_RECORDS', category: 'Common', defaultMessage: 'No records to display'},
            { key: 'EVENT_CANCELED', category: 'EVENT_MANAGEMENT', defaultMessage: 'Event Canceled'},
            { key: "START_DATE", category: 'TABLET', defaultMessage: "Start Date"},
            { key: "OWNER", category: 'Common', defaultMessage: "Owner"},
        ].map(msg => this.ctrl.pageCtrl.getMessage(msg)));
        this.addLabel = addLabel;
        this.removeLabel = removeLabel;
        this.cancelLabel = cancelLabel;
        this.viewCvLabel = viewCvLabel;
        this.detailsHeaderLabel = detailsHeaderMsg;
        this.servicesHeaderMsg = servicesHeaderMsg;
        this.recentEventsHeaderMsg = recentEventsHeaderMsg;
        this.trainingHeaderMsg = trainingHeaderMsg;
        this.topicMsg = topicMsg;
        this.noRecordsLabel = noRecordsLabel;
        this.eventCanceled = eventCanceledMsg;

        await this.objectInfoLabels;

        this.trainingColumns = [{
            fieldName: 'name',
            label: this.topicMsg,
            hideDefaultActions: true
        },{
            fieldName: 'endDate',
            label: this.speakerQualificationEndDateLabel,
            hideDefaultActions: true
        }];
        this.recentEventsColumns = [{
            fieldName: 'eventName',
            label: this.eventObjectLabel,
            hideDefaultActions: true
        },{
            fieldName: 'startTime',
            label: startDateLabel,
            type: 'date',
            typeAttributes: {
                year: 'numeric',
                month: 'numeric',
                day: 'numeric'
            },
            hideDefaultActions: true
        },{
            fieldName: 'speakerStatus',
            label: this.emEventSpeakerStatusLabel,
            hideDefaultActions: true
        },{
            fieldName: 'ownerName',
            label: ownerLabel,
            hideDefaultActions: true
        }];
    }

    viewCV(event) {
        event.preventDefault();
        event.stopPropagation();
        window.open(this.cv);
    }

    cancel() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    confirmation() {
        this.dispatchEvent(new CustomEvent('update', {
            detail: {
                id: this.id,
                checked: Boolean(!this.isChecked)
            }
        }));
    }
}