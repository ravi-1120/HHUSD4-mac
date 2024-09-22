/* eslint-disable no-param-reassign */
/* eslint-disable class-methods-use-this */
import START_TIME from '@salesforce/schema/EM_Event_vod__c.Start_Time_vod__c';
import TOPIC from '@salesforce/schema/EM_Event_vod__c.Topic_vod__c';
import attendeeDetailsTemplate from '../templates/attendeeSelectionDetails.html';
import DefaultAttendeeDetailsStrategy from '../support/defaultAttendeeDetailsStrategy';
import OutsideTerritoryAttendeeDetailsStrategy from '../support/outsideTerritoryAttendeeDetailsStrategy';

const LAST_TOPIC = 'LastTopic';
const ADDRESS = 'Address';
const RECENT_EVENTS = 'RecentEvents';
const MCCP = 'MCCP';
const ATTENDEE_FIELD_DETAILS_EXCLUSIONS = ['Id', 'Name'];

export default class AttendeeSelectionDetailsPopoverController {
    constructor(pageCtrl) {
        this.pageCtrl = pageCtrl;
        this.attendeeFields = {};
    }

    get attendeeService() {
        return this.pageCtrl.service;
    }

    get eventId() {
        return this.pageCtrl.eventId;
    }

    getIdForDetails(record) {
        return record.Id;
    }

    hasAttendeeField(attendeeFields, keyword) {
        return attendeeFields.some(field => field.apiName === keyword);
    }

    getAttendeeDataRetrievalStrategy(record, id) {
        let strategy = new DefaultAttendeeDetailsStrategy(this.attendeeService);
        if (record.outside) {
            strategy = new OutsideTerritoryAttendeeDetailsStrategy(id, this.eventId, this.attendeeService);
        }
        return strategy;
    }

    async getDetails(id, record) {
        const attendeeDetails = {};
        const object = this.pageCtrl.getObjectType(id);
        const strategy = this.getAttendeeDataRetrievalStrategy(record, id, object);
        const attendeeFields = await this.getAttendeeFields(object);
        if (attendeeFields.length > 0) {
            const eventStartTime = this.pageCtrl.record.fields[START_TIME.fieldApiName].value;
            const eventTopic = this.pageCtrl.record.fields[TOPIC.fieldApiName].value;
            
            const promises = [];
            const nonKeywordAttendeeFields = attendeeFields.filter(field => !field.isKeyword && !ATTENDEE_FIELD_DETAILS_EXCLUSIONS.includes(field.apiName));
            if (nonKeywordAttendeeFields.length > 0) {
                attendeeDetails.identifier = this.getValue(record, nonKeywordAttendeeFields[0].apiName, object);
                attendeeDetails.details = this.initDetailsSection(nonKeywordAttendeeFields, record, object);
            }
            if (this.hasAttendeeField(attendeeFields, LAST_TOPIC) && eventTopic) {
                promises.push(strategy.getLastTopicDate(object, id, this.eventId, eventTopic).then(response => {
                    attendeeDetails.lastTopicDate = response;
                }));
            }
            if (this.hasAttendeeField(attendeeFields, ADDRESS)) {
                promises.push(strategy.getAddresses(id).then(response => {
                    attendeeDetails.addresses = response;
                }));
            }
            if (this.hasAttendeeField(attendeeFields, RECENT_EVENTS)) {
                promises.push(strategy.getRecentEvents(object, id, this.eventId).then(response => {
                    attendeeDetails.recentEvents = response;
                }));
            }
            if (this.hasAttendeeField(attendeeFields, MCCP)) {
                promises.push(strategy.getMCCP(id, eventStartTime).then(this.adaptCyclePlan).then(response => {
                    attendeeDetails.mccp = response;
                }));
            }
            await Promise.allSettled(promises);
        }
        return attendeeDetails;
    }

    async getAttendeeFields(object) {
        if (!this.attendeeFields[object]) {
            this.attendeeFields[object] = await this.pageCtrl.getAttendeeFields(object);
        }
        return this.attendeeFields[object];
    }

    getValue(record, fieldName, object) {
        let value = record[fieldName];
        if (this.pageCtrl.objectInfo[object]?.fields[fieldName]?.dataType === 'Reference') {
            const lookupRecord = record[this.pageCtrl.objectInfo[object].fields[fieldName].relationshipName];
            value = lookupRecord?.Name;
        }
        return value;
    }

    initDetailsSection(nonKeywordAttendeeFields, record, object) {
        let items = [];
        const attendeeFields = [];
        nonKeywordAttendeeFields.forEach(field => {
            items.push({
                label: field.label,
                value: this.getValue(record, field.apiName, object),
                apiName: field.apiName,
                htmlFormatted: this.pageCtrl.objectInfo[object]?.fields[field.apiName]?.htmlFormatted
            });
            if (items.length === 2) {
                attendeeFields.push({ id: attendeeFields.length, items });
                items = [];
            }
        });
        if (items.length === 1) {
            items.push({ apiName: ''});
            attendeeFields.push({ id: attendeeFields.length, items });
        }
            
        return attendeeFields;
    }

    adaptCyclePlan(mccp) {
        const mcCyclePlans = { plans: [], channels: [] };
        if (mccp?.length > 0) {
            mccp.forEach( (plan, idx) => { 
                // plan has 1 entry representing a single cycle plan (string -> list of objects)
                Object.entries(plan).forEach(([key, value]) => {
                    mcCyclePlans.plans.push({ label: key, value: idx.toString() });
                    mcCyclePlans.channels.push(
                        value.map((channel, i) => ({ ...channel, id: i})).slice(0, 10)
                    );
                });
            });
        }
        return mcCyclePlans;
    }

    getTemplate() {
        return attendeeDetailsTemplate;
    }
}