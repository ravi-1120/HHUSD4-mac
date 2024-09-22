import { api, track, wire, LightningElement } from 'lwc';
import { getObjectInfos } from 'lightning/uiObjectInfoApi';
import EM_EVENT from '@salesforce/schema/EM_Event_vod__c';
import EM_ATTENDEE from '@salesforce/schema/EM_Attendee_vod__c';
import STATUS from '@salesforce/schema/EM_Attendee_vod__c.Status_vod__c';
import MC_CYCLE_PLAN from '@salesforce/schema/MC_Cycle_Plan_vod__c';
import MC_CYCLE_PLAN_CHANNEL from '@salesforce/schema/MC_Cycle_Plan_Channel_vod__c';
import CHANNEL from '@salesforce/schema/MC_Cycle_Plan_Channel_vod__c.Channel_vod__c';
import GOAL from '@salesforce/schema/MC_Cycle_Plan_Channel_vod__c.Team_Channel_Activity_Goal_vod__c';
import REMAINING from '@salesforce/schema/MC_Cycle_Plan_Channel_vod__c.Team_Channel_Activity_Remaining_vod__c';

export default class AttendeeSelectionDetailsPopover extends LightningElement {
    
    @wire(getObjectInfos, { objectApiNames: [ EM_EVENT, EM_ATTENDEE, MC_CYCLE_PLAN_CHANNEL, MC_CYCLE_PLAN ] })
    wireObjectInfo({error, data}) {
        if (data?.results) {
            data.results.forEach(response => {
                if (response?.statusCode === 200) {
                    const objectInfo = response.result;
                    const objectApiName = objectInfo.apiName;
                    if (objectApiName === EM_EVENT.objectApiName) {
                        this.eventObjectLabel = objectInfo.label;
                    } else if (objectApiName === EM_ATTENDEE.objectApiName) {
                        this.emAttendeeStatusLabel = objectInfo.fields[STATUS.fieldApiName]?.label;
                    } else if (objectApiName === MC_CYCLE_PLAN.objectApiName) {
                        this.mccpHeaderLabel = objectInfo.label;

                    } else if (objectApiName === MC_CYCLE_PLAN_CHANNEL.objectApiName) {
                        this.mccpColumns = [{
                            label: objectInfo.fields[CHANNEL.fieldApiName]?.label,
                            fieldName: 'label',
                            hideDefaultActions: true
                        },{
                            label: objectInfo.fields[GOAL.fieldApiName]?.label,
                            fieldName: 'goal',
                            hideDefaultActions: true
                        },{
                            label: objectInfo.fields[REMAINING.fieldApiName]?.label,
                            fieldName: 'remaining',
                            hideDefaultActions: true
                        }];
                    }
                }
            });
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

    get loading() {
        return this.requests.length > 0;
    }

    get isSelected() {
        return this.record.checked;
    }

    get title() {
        return this.record.Name;
    }

    get lastTopic() {
        let lastTopic = '';
        if (this.lastTopicMsg && this.lastTopicDate) {
            lastTopic = this.lastTopicMsg.replace('{0}', this.lastTopicDate);
        }
        return lastTopic;
    }

    get confirmationLabel() {
        return this.isSelected ? this.removeLabel : this.addLabel;
    }

    identifier;
    sections = {};
    mcCyclePlans;
    mcCyclePlanChannels;
    selectedPlan;
    selectedPlanChannels;
    addressesColumns = [{
        fieldName: 'formattedAddress'
    }];

    // Field Label Defaults
    eventObjectLabel = 'Event';
    emAttendeeStatusLabel = 'Status';
    channelLabel = 'Channel';
    teamChannelActivityRemaining = 'Team Channel Activity Remaining';
    teamChannelActivtyGoal = 'Team Channel Activity Goal';

    objectInfoLabels = new Promise(resolve => { this.resolveObjectInfoLabels = resolve; });

    async init() {
        await Promise.all([
            this.getAttendeeFields(),
            this.getMessages()
        ]);
        this.recentEventsHeaderLabel = this.recentEventsHeaderMsg?.replace('{0}', `(${this.recentEvents?.length})`);
        this.addressesHeaderLabel = this.addressesHeaderMsg?.replace('{0}', `(${this.addresses?.length})`);
    }

    async getAttendeeFields() {
        const attendeeFields = await this.ctrl.getDetails(this.ctrl.getIdForDetails(this.record), this.record);
        this.identifier = attendeeFields.identifier;
        this.attendeeFields = attendeeFields.details;
        this.addresses = attendeeFields.addresses;
        this.recentEvents = attendeeFields.recentEvents;
        this.lastTopicDate = attendeeFields.lastTopicDate;
        this.initMccp(attendeeFields.mccp);
    }

    initMccp(mccp) {
        if (mccp) {
            this.mcCyclePlans = mccp?.plans;
            this.mcCyclePlanChannels = mccp?.channels;
            if (this.mcCyclePlans && this.mcCyclePlanChannels) {
                this.selectedPlan = '0';
                this.selectedPlanChannels = this.mcCyclePlanChannels[this.selectedPlan];
            }
        }
    }

    handleCyclePlan(event) {
        this.selectedPlan = event.detail.value;
        this.selectedPlanChannels = this.mcCyclePlanChannels[this.selectedPlan];
    }

    async getMessages() {
        const [addLabel, removeLabel, cancelLabel, detailsHeaderMsg, addressesHeaderMsg, recentEventsHeaderMsg, noRecordsLabel, startDateLabel, ownerLabel, lastTopicMsg, planLabel, noActiveCyclePlanMsg] = await Promise.all([
            { key:'ADD_ATTENDEE', category: 'EVENT_MANAGEMENT', defaultMessage: 'Add Attendee' },
            { key: 'REMOVE_ATTENDEE', category: 'EVENT_MANAGEMENT', defaultMessage: 'Remove Attendee' },
            { key: 'CANCEL', category: 'Common', defaultMessage: 'Cancel'},
            { key: 'PAGE_LAYOUT_TITLE', category: 'Common', defaultMessage: 'Details' },
            { key: 'ADDRESSES', category: 'EVENT_MANAGEMENT' , defaultMessage: 'Addresses {0}' },
            { key: 'RECENT_EVENTS', category: 'EVENT_MANAGEMENT', defaultMessage: 'Recent Events {0}'},
            { key: 'NO_RECORDS', category: 'Common', defaultMessage: 'No records to display'},
            { key: "START_DATE", category: 'TABLET', defaultMessage: "Start Date"},
            { key: "OWNER", category: 'Common', defaultMessage: "Owner"},
            { key: 'LAST_TOPIC_MESSAGE', category: 'EVENT_MANAGEMENT', defaultMessage: 'This account last heard this topic on {0}' },
            { key: 'MCCP_PLAN', category: 'Multichannel', defaultMessage: 'Plan' },
            { key: 'CYCLE_PLAN_NO_DATA_MESSAGE', category: 'TABLET', defaultMessage: 'No active cycle plan.' },
        ].map(msg => this.ctrl.pageCtrl.getMessage(msg)));
        this.addLabel = addLabel;
        this.removeLabel = removeLabel;
        this.cancelLabel = cancelLabel;
        this.detailsHeaderLabel = detailsHeaderMsg;
        this.addressesHeaderMsg = addressesHeaderMsg;
        this.recentEventsHeaderMsg = recentEventsHeaderMsg;
        this.noRecordsLabel = noRecordsLabel;
        this.lastTopicMsg = lastTopicMsg;
        this.planLabel = planLabel;
        this.noActiveCyclePlanLabel = noActiveCyclePlanMsg;

        await this.objectInfoLabels;

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
            fieldName: 'attendeeStatus',
            label: this.emAttendeeStatusLabel,
            hideDefaultActions: true
        },{
            fieldName: 'ownerName',
            label: ownerLabel,
            hideDefaultActions: true
        }];
    }

    cancel() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    confirmation() {
        this.dispatchEvent(new CustomEvent('update', {
            detail: {
                id: this.id,
                checked: Boolean(!this.isSelected)
            }
        }));
    }
}