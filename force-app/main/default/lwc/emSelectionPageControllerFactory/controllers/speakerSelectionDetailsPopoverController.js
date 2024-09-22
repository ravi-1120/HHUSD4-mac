import START_TIME from '@salesforce/schema/EM_Event_vod__c.Start_Time_vod__c';
import STATUS from '@salesforce/schema/EM_Speaker_vod__c.Status_vod__c';
import speakerDetails from '../templates/speakerSelectionDetails.html';

const SPEAKER_FIELD_DETAILS_EXCLUSIONS = ['CV','RecentEvents', 'Training', 'Services', 'Id', 'Name'];
const CV_ATTACHMENT_URL = '/servlet/servlet.FileDownload?file=';
const CV_FILE_URL = '/sfc/servlet.shepherd/version/renditionDownload?rendition=svgz&versionId=';

export default class SpeakerSelectionDetailsPopoverController {
    
    constructor(pageCtrl) {
        this.pageCtrl = pageCtrl;
    }

    get speakerFields() {
        return this.pageCtrl.speakerFields;
    }

    get speakerService() {
        return this.pageCtrl.service;
    }

    get nonKeywordSpeakerFields() {
        return this.speakerFields.filter(field => !SPEAKER_FIELD_DETAILS_EXCLUSIONS.includes(field.apiName));
    }

    hasSpeakerField(keyword) {
        return this.speakerFields.some(field => field.apiName === keyword);
    }

    async initSpeakerFieldModel(record) {
        const speakerFields = [];
        let items = [];
        for (const field of this.nonKeywordSpeakerFields) {
            items.push({
                label: field.label,
                value: this.getValue(record, field.apiName),
                apiName: field.apiName,
                htmlFormatted: this.pageCtrl.objectInfo.fields[field.apiName]?.htmlFormatted
            });
            if (items.length === 2) {
                speakerFields.push({ id: speakerFields.length, items });
                items = [];
            }
        }
        if (items.length === 1) {
            items.push({});
            speakerFields.push({ id: speakerFields.length, items });
        }
        return speakerFields;
    }

    getValue(record, fieldName) {
        let value = record[fieldName];
        if (fieldName === STATUS.fieldApiName) {
            value = record[this.pageCtrl.statusAlias];
        } else if (this.pageCtrl.objectInfo.fields[fieldName]?.dataType === 'Reference') {
            const lookupRecord = record[this.pageCtrl.objectInfo.fields[fieldName].relationshipName];
            value = lookupRecord?.Name;
        }
        return value;
    }

    async getCvLink(speakerId) {
        let cv = '';
        const response = await this.speakerService.getCV(speakerId);
        const data = response.data[0];
        if (data?.Id) {
            cv = CV_ATTACHMENT_URL + data.Id;
            if (data?.contentdocument){
                cv = CV_FILE_URL + data.Id;
            }
        }
        return cv;
    }

    async getServices(speakerId, startTime) {
        return this.speakerService.getSpeakerServices(speakerId, startTime);
    }

    async getTraining(speakerId, startTime) {
        return this.speakerService.getTraining(speakerId, startTime);
    }

    async getRecentEvents(speakerId) {
        const recentEventsResponse = await this.speakerService.getRecentEvents(speakerId, this.pageCtrl.eventId); 
        const recentEvents = recentEventsResponse.data?.slice(0,10);
        const ownerIds = recentEvents.map(event => event['Event_vod__r.OwnerId']).filter((value, index, self) => self.indexOf(value) === index);
        const owners = {};
        if (ownerIds.length > 0) {
            const ownersResponse = await this.speakerService.getOwners(ownerIds);
            for (const owner of ownersResponse.data) {
                owners[owner.Id] = owner.Name;
            }
        }
        for (const event of recentEvents) {
            event.eventName = event['Event_vod__r.Name'];
            event.speakerStatus = event.Status_vod__c;
            event.startTime = event['Event_vod__r.Start_Time_vod__c'];
            event.ownerName = owners[event['Event_vod__r.OwnerId']] || '';
        }
        return recentEvents;
    }

    async getDetails(record) {
        const speakerId = record.Id;
        const startTime = this.pageCtrl.record.fields[START_TIME.fieldApiName].value;

        const details = {};
        const requests = [];
        requests.push(this.initSpeakerFieldModel(record).then(fields => { details.fields = fields; }));
        if (this.hasSpeakerField('CV')) {
            requests.push(this.getCvLink(speakerId).then(cv => { details.cv = cv; }));
        }
        if (this.hasSpeakerField('Services')) {
            requests.push(this.getServices(speakerId, startTime).then(services => { details.services = services; }));
        }
        if (this.hasSpeakerField('RecentEvents')) {
            requests.push(this.getRecentEvents(speakerId).then(recentEvents => { details.recentEvents = recentEvents; }));
        }
        if (this.hasSpeakerField('Training')) {
            requests.push(this.getTraining(speakerId, startTime).then(training => { details.training = training; }));
        }
        await Promise.allSettled(requests);
        return details;
    }

    getTemplate() {
        return speakerDetails;
    }

}