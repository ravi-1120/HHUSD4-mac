public without sharing class VeevaDocumentedInterestTriggerHandler extends VeevaTriggerHandler {
    private List<Documented_Interest_vod__c> newDocumentedInterests;
    private List<Documented_Interest_vod__c> oldDocumentedInterests;
    private Map<ID, Documented_Interest_vod__c> newADocumentedInterestsMap;
    private Map<ID, Documented_Interest_vod__c> oldDocumentedInterestsMap;

    protected override void preTrigger(
        List<SObject> triggerNew,
        List<SObject> triggerOld,
        Map<ID, SObject> triggerNewMap,
        Map<ID, SObject> triggerOldMap
    ) {
        newDocumentedInterests = (List<Documented_Interest_vod__c>) triggerNew;
        oldDocumentedInterests = (List<Documented_Interest_vod__c>) triggerOld;
        newADocumentedInterestsMap = (Map<ID, Documented_Interest_vod__c>) triggerNewMap;
        oldDocumentedInterestsMap = (Map<ID, Documented_Interest_vod__c>) triggerOldMap;
    }

    protected override String sObjectType() {
        return 'Documented_Interest_vod__c';
    }

    protected override void beforeInsert() {
        for (Integer i = 0; i < this.newDocumentedInterests.size(); i++) {
            this.newDocumentedInterests[i].Expiration_Date_vod__c = this.newDocumentedInterests[i].Calculated_Expiration_Date_vod__c;
        }
    }
}