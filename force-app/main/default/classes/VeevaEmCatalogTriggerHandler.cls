public without sharing class VeevaEmCatalogTriggerHandler extends VeevaTriggerHandler{

    private List<EM_Catalog_vod__c> newCatalogs = new List<EM_Catalog_vod__c>();


    protected override void preTrigger(List<SObject> triggerNew, List<SObject> triggerOld, Map<ID, SObject> triggerNewMap, Map<ID, SObject> triggerOldMap) {
        this.newCatalogs = (List<EM_Catalog_vod__c>) triggerNew;

    }

    protected override boolean doRecursionCheck() {
        return true;
    }

    protected override String sObjectType() {
        return 'EM_Catalog_vod__c';
    }

    protected override void afterUpdate() {
		VeevaEmCatalogTriggerUtil.withdrawVeevaDistribution(newCatalogs);
    }
}