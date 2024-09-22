export default class OutsideTerritoryAttendeeDetailsStrategy {
    
    constructor(recordId, eventId, service) {
        this.service = service;
        this.request = this.service.getOutsideTerritoryRecordDetails(recordId, eventId);
    }

    async getLastTopicDate() {
        const res = await this.request;
        return res?.lastTopicDate;
    }

    async getAddresses() {
        const res = await this.request;
        return res?.addresses.map(formattedAddress => ({ formattedAddress }));
    }

    async getRecentEvents() {
        const res = await this.request;
        const recentEvents = res?.recentEvents?.slice(0, 10) ?? [];
        const owners = await this.service.getOwners(recentEvents.map(({ ownerId }) => ownerId));
        const ownerMap = {};
        owners.forEach(owner => {
            ownerMap[owner.Id] = owner.Name;
        });
        return recentEvents.map(event => ({
            eventName: event.name,
            attendeeStatus: event.attendeeStatus,
            startTime: event.startDatetime ?? '',
            ownerName: ownerMap[event.ownerId],
        }));
    }

    async getMCCP() {
        const res = await this.request;
        return res?.cyclePlans;
    }

}