public without sharing class VeevaScientificInterest {
    @AuraEnabled (cacheable = false)
    public static Boolean isInUse(Id scientificInterestId) {
        List<Documented_Interest_vod__c> documentedInterests = [SELECT Id FROM Documented_Interest_vod__c WHERE Scientific_Interest_vod__c = :scientificInterestId];
        return documentedInterests != null && documentedInterests.size() > 0;
    }
}