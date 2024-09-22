trigger VeevaCallTrigger on Call2_vod__c (before insert, before update, before delete, after insert, after update, after delete) {
	VeevaTriggerHandler handler = new VeevaCallTriggerHandler();
    handler.handleTrigger();
}