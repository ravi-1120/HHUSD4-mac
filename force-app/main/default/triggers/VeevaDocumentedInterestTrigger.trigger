trigger VeevaDocumentedInterestTrigger on Documented_Interest_vod__c (before insert) {
    VeevaTriggerHandler handler = new VeevaDocumentedInterestTriggerHandler();
    handler.handleTrigger();
}