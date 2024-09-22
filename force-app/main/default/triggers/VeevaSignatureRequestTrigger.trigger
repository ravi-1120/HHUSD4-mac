trigger VeevaSignatureRequestTrigger on Signature_Request_vod__c (before insert, before update, after insert, after update) {
	VeevaTriggerHandler handler = new VeevaSignatureRequestTriggerHandler();
    handler.handleTrigger();
}