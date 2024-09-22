public with sharing class VeevaAdminController {
    @AuraEnabled(cacheable=true)
    public static string getSpeakerPortalServer() {
        try {
            return Veeva_Common_vod__c.getValues('Main').Speaker_Portal_Server_vod__c;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}