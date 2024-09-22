public with sharing class MSD_CORE_HEQ_BannerController {
    @AuraEnabled(cacheable=true)
    public static String getUserProfileName() {
        Id userId = UserInfo.getUserId();
        User user = [SELECT Id, Profile.Name FROM User WHERE Id = :userId LIMIT 1];
        System.debug('User ID: ' + userId);
        System.debug('User Profile Name: ' + user.Profile.Name);
        return user.Profile.Name;
    }

    @AuraEnabled(cacheable=true)
    public static List<MSD_CORE_HEQ_Banner__mdt> getBannerConfigs() {
        return [SELECT Id, Banner_Name__c, Banner_URL__c, Profile__c,Tab_Image_URL__c,Mobile_Image_URL__c  FROM MSD_CORE_HEQ_Banner__mdt];
    }
    @AuraEnabled(cacheable=true)
    public static String getStaticResourceURL(String resourceName) {
        return URL.getOrgDomainUrl().toExternalForm() + '/resource/' + EncodingUtil.urlEncode(resourceName, 'UTF-8');
    }
}