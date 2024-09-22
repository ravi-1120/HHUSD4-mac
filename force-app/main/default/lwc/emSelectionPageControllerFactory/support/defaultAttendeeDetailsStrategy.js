export default class DefaultAttendeeDetailsStrategy {
    
    constructor(service) {
        this.service = service;
    }

    async getLastTopicDate(object, id, eventId, eventTopic) {
        const topicDate = await this.service.getLastTopicDate(object, id, eventId, eventTopic);
        return topicDate;
    }

    async getAddresses(recordId) {
        const addressRecords = await this.service.getAccountAddresses(recordId);
        return addressRecords.map(addressRecord => this.constructAddress(addressRecord));
    }

    constructAddress(addressRecord) {
        let formattedAddress = '';
        if(addressRecord.Name) { 
            formattedAddress += `${addressRecord.Name} `;
        }
        if(addressRecord.Address_line_2_vod__c) {
            formattedAddress += `${addressRecord.Address_line_2_vod__c} `;
        }
        if(addressRecord.City_vod__c) {
            formattedAddress += `${addressRecord.City_vod__c} `;
        }
        if(addressRecord.State_vod__c) {
            formattedAddress += `${addressRecord.State_vod__c} `;
        }
        if(addressRecord.Zip_vod__c) {
            formattedAddress += `${addressRecord.Zip_vod__c} `;
        }
        if(addressRecord.Country_vod__c) {
            formattedAddress += addressRecord.Country_vod__c;
        }
        return { formattedAddress };
    }

    async getRecentEvents(object, recordId, eventId) {
        const recentlyAttendedEvents = await this.service.getRecentEvents(object, recordId, eventId); 
        return recentlyAttendedEvents.map(attendee => {
            const event = attendee.Event_vod__r ?? {};
            return {
                eventName: event.Name,
                attendeeStatus: attendee.Status_vod__c,
                startTime: event.Start_Time_vod__c ?? '',
                ownerName: event.Owner?.Name ?? '',
            }
        });
    }

    async getMCCP(recordId, eventStartDate) {
        const mccp = await this.service.getMCCP(recordId, eventStartDate);
        return mccp;
    }

}