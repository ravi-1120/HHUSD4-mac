/* eslint-disable class-methods-use-this */
import EM_EVENT_SPEAKER from '@salesforce/schema/EM_Event_Speaker_vod__c';
import SPEAKER from '@salesforce/schema/EM_Event_Speaker_vod__c.Speaker_vod__c';
import getServices from '@salesforce/apex/EmSpeakerSelection.getServices';
import getTraining from '@salesforce/apex/EmSpeakerSelection.getTraining';

export default class SpeakerSelectionService {

    veevaDataService;

    constructor(veevaDataService) {
        this.veevaDataService = veevaDataService;
    }

    async createSpeakers(speakers) {
        const path = `/api/v1/base/data/${EM_EVENT_SPEAKER.objectApiName}s`;
        const body = {};
        body[EM_EVENT_SPEAKER.objectApiName] = speakers;
        const saveResult = {};
        try {
            const response = await this.veevaDataService.sendRequest('PUT', path, {}, body, 'createSpeakers');
            if (response.recordCount > -1) {
                if (response.insertCount > 0) {
                    saveResult.insertCount = response.insertCount;
                }
                if (response.failedCount > 0) {
                    saveResult.failedInsertCount = response.failedCount;
                    const {failedRecords } = response;
                    if (failedRecords?.length > 0) {
                        saveResult.failedInsertRecords = failedRecords.map(record => ({
                            id: record[EM_EVENT_SPEAKER.objectApiName][SPEAKER.fieldApiName],
                            messages: record.insertErrors.map(error => error.message)
                        }));
                    }
                }
            }
        } catch (ex) {
            if (ex.status === -1) {
                saveResult.failedInsertCount = speakers.length;
                saveResult.failedInsertMessage = ex.message;
            }
        }
        return saveResult;
    }

    async deleteSpeakers(speakerIds) {
        const path = `/api/v1/layout3/data/${EM_EVENT_SPEAKER.objectApiName}/bulk`;
        const body = {
            Ids: speakerIds
        }
        const saveResult = {};
        try {
            const response = await this.veevaDataService.sendRequest('DELETE', path, {}, body, 'deleteSpeakers');
            if (response.status === 0) {
                saveResult.deleteCount = speakerIds.length;
            }
        } catch (ex) {
            if (ex.status === -1) {
                saveResult.failedDeleteCount = speakerIds.length;
                saveResult.failedDeleteMessage = ex.message;
            }
        }
        return saveResult;
    }

    async getCV(speakerId) {
        const path = `/api/v1/em.speaker/speakerCV/${speakerId}`;
        const response = await this.veevaDataService.sendRequest('GET', path, {}, null, 'getCV');
        return response;
    }

    async getSpeakerServices(speakerId, startTime) {
        return getServices({speakerId, startTime});
    }

    async getRecentEvents(speakerId, eventId) {
        const query = `Speaker_vod__c;=;${speakerId},AND,Event_vod__c;!=;${eventId},AND,Event_vod__c;!=;null`;
        const path = '/api/v1/base/data/EM_Event_Speaker_vod__c/search';
        const params = {
            q: query,
            sort: 'Event_vod__r.Start_Time_vod__c',
            descend: true,
            supplementFields :'Event_vod__r.Name, Event_vod__r.Start_Time_vod__c, Event_vod__r.OwnerId, Event_vod__r.Status_vod__c, toLabel(Status_vod__c)'
        };
        const response = await this.veevaDataService.sendRequest('GET', path, params, null, 'getRecentEvents');
        return response;
    }
    
    async getOwners(ownerIds) {
        const path = '/api/v1/base/data/User';
        const params = {
                fields: 'Id, Name',
                ids : ownerIds
        };
        const response = await this.veevaDataService.sendRequest('GET', path, params, null, 'getOwners');
        return response;
    }
    
    async getTraining(speakerId, startTime) {
        return getTraining({speakerId, startTime});
    }

    async getSpeakerRuleWarnings(speakerIds, eventId) {
        const path = `/api/v1/em.speaker/speaker-rule-warnings/${eventId}`;
        const params = {
            platform: 'Online',
        };
        const response = await this.veevaDataService.sendRequest('PUT', path, params, speakerIds, 'getSpeakerRuleWarnings');
        if (response.status !== 0) {
            throw response;
        }
        return response.data;
    }
}