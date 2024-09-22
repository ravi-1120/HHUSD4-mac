trigger VeevaMeetingRequestTrigger on Meeting_Request_vod__c (before insert, before update, after insert) {
	VeevaTriggerHandler handler = new VeevaMeetingRequestTriggerHandler();

    handler.handleTrigger();
}