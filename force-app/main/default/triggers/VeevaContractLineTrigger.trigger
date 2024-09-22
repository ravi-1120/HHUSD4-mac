trigger VeevaContractLineTrigger on Contract_Line_vod__c (before insert, before update, before delete, after insert, after update, after delete) {
    VeevaTriggerHandler handler = new VeevaContractLineTriggerHandler();
    handler.handleTrigger();
}