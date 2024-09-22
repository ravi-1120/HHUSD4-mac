trigger VeevaContentTrigger on Veeva_Content_vod__c (before insert, before update, after update, before delete) {
    VeevaTriggerHandler handler = new VeevaContentTriggerHandler();
    handler.handleTrigger();
}