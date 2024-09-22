trigger VeevaAcknowledgementOfContentTrigger on Content_Acknowledgement_vod__c (before insert, before update, before delete, after insert, after update) {
	VeevaTriggerHandler handler = new VeevaAOCTriggerHandler();
    handler.handleTrigger();
}