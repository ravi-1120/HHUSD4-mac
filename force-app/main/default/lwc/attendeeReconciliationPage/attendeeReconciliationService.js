/* eslint-disable class-methods-use-this */
import { getService } from 'c/veevaServiceFactory';
import getFilters from '@salesforce/apex/VeevaEmAttendeeReconciliation.getFilters';
import getWalkInCounts from '@salesforce/apex/VeevaEmAttendeeReconciliation.getWalkInCounts';
import getWalkInAttendees from '@salesforce/apex/VeevaEmAttendeeReconciliation.getWalkInAttendees';
import getCustomSettingsForNewButtonConfig from '@salesforce/apex/VeevaEmAttendeeReconciliation.getCustomSettingsForNewButtonConfig';

const EVENTS_ONLINE = 'EVENTS_ONLINE';
const EM_RECONCILIATION_BASE_URL = `/api/v1/em.reconciliation`;
export default class AttendeeReconciliationService {
    #dataService;

    constructor() {
        this.#dataService = getService('dataSvc');
    }

    async getCounts(eventId) {
        let counts = {};
        try {
            counts = await getWalkInCounts({ eventId });
        } catch (e) {
            counts = {total: 0, reconciled: 0, dismissed: 0, pendingVerification: 0, needsReconciliation: 0};
        }
        return counts;
    }

    async getWalkIns(eventId, fields, walkInStatuses, walkInTypes, sortBy, sortDirection) {
        let walkIns = [];
        try {
            walkIns = await getWalkInAttendees({ eventId, fields, walkInStatuses, walkInTypes, sortBy, sortDirection });
        } catch (e) {
            walkIns = [];
        }
        return walkIns;
    }

    async getFilters() {
        let filterMap = {};
        try {
            const filters = await getFilters();
            if (filters?.length > 0) {
                filters.forEach(filter => {
                    const filterCopy = {
                        id: filter.fieldName,
                        ...filter
                    };
                    filterMap[filter.fieldName] = filterCopy;
                });
            }
        } catch (e) {
            filterMap = {};
        }
        return filterMap;
    }

    async dismissAttendees(eventId, attendeeList) {
        const path = `${EM_RECONCILIATION_BASE_URL}/${eventId}/attendees`;
        let response = {};
        try {
            response = await this.#dataService.sendRequest('PUT', path, {'origin': 'EVENTS_ONLINE'}, { EM_Attendee_vod__c: attendeeList }, 'dismissAttendees');
        } catch (e) {
            response = e;
        }
        return response;
    }

    async completeReopenReconciliation(eventId, complete) {
        const data = {
            Id: eventId,
            type: 'EM_Event_vod__c',
            Attendee_Reconciliation_Complete_vod__c: complete
        };
        let response = {};
        try {
            response = await this.#dataService.save({type: 'EM_Event_vod__c', data });
        } catch (e) {
            response = e;
        }
        return response;
    }

    async searchForMatches(eventId, attendeeId, firstName, lastName, email, phone, city, zip, additionalWalkInFields) {
        const path = `${EM_RECONCILIATION_BASE_URL}/search`;
        const params = Object.fromEntries(Object.entries({
            eventId,
            attendeeId,
            firstName,
            lastName,
            phone,
            email,
            city,
            zip,
            additionalWalkInFields,
            origin: EVENTS_ONLINE
        }).filter(([,value]) => value)); // Remove params that are falsy

        const response = {};
        try {
            const res = await this.#dataService.sendRequest('GET', path, params, null, 'walkInSearch');
            response.message = res.message;
            response.data = this.adaptSearchResults(res.data);
        } catch (e) {
            response.status = -1;
            response.data = [];
            response.message = e.message;
        }
        return response;
    }   

    adaptSearchResults(data) {
        return data?.map(result => {
            const { lastName: last, firstName: first, parentName } = result;
            return {
                ...result,
                name: {
                    parentName,
                    firstName: first,
                    lastName: last
                },
            };
        });
    }

    async retrieveMatch(walkInReferenceId, attendeeId, additionalWalkInFields) {
        const path = `${EM_RECONCILIATION_BASE_URL}/retrieve/`;
        const params = {
            Id: walkInReferenceId,
            attendeeId,
            additionalWalkInFields,
            origin: EVENTS_ONLINE
        }
        const response = {};  
        try {
            const res = await this.#dataService.sendRequest('GET', path, params, null, 'retrieveMatch');
            response.data = this.adaptSearchResults(res.data);
        } catch (e) {
            response.status = -1;
            response.data = [];
        }
        return response;
    }

    async updateAttendee(data) {
        const path = `${EM_RECONCILIATION_BASE_URL}/attendees/`;
        let response = {};  
        try {
            response = await this.#dataService.sendRequest('PUT', path, {origin: EVENTS_ONLINE}, data, 'updateAttendee');
        } catch (e) {
            response = e;
        }
        return response;
    }

    async getCustomSettingsForNewButtonConfig() {
        let customSettingValues = {};
        try {
            customSettingValues = await getCustomSettingsForNewButtonConfig();
        } catch (e) {
            customSettingValues = {};
        }
        return customSettingValues;
    }

    async getAttendeeRuleWarnings(attendees, eventId) {
        const path = '/api/v1/attendee.hub/attendee-rule-warnings';
        const params = {
            platform: 'Online',
        }
        const data = {
            EM_Attendee_vod__c: attendees,
            Event_vod__c: eventId,
        }
        const response = {};
        try {
            const res = await this.#dataService.sendRequest('PUT', path, params, data, 'getAttendeeRuleWarnings');
            response.data = res.data
        } catch (e) {
            response.status = -1;
            response.data = [];
        }
        return response;
    }
}