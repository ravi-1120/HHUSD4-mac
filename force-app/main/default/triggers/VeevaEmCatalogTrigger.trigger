trigger VeevaEmCatalogTrigger on EM_Catalog_vod__c (before insert, before update, before delete, after insert, after update) {
    VeevaTriggerHandler handler = new VeevaEmCatalogTriggerHandler();
    handler.handleTrigger();
}