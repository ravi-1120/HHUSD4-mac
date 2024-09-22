trigger VeevaVeevaDistributionTrigger on Veeva_Distribution_vod__c (after insert, after update, before delete, before update) {
    
    VeevaTriggerHandler handler = new VeevaDistributionTriggerHelper();
    handler.handleTrigger();
    
}