public with sharing class WeChatSettings {
    public static WeChat_Settings_vod__c getWeChatSettings() {
        return WeChat_Settings_vod__c.getInstance();
    }

    @AuraEnabled(cacheable=true)
    public static String getDomainUrl() {
        WeChat_Settings_vod__c weChatSettings = WeChatSettings.getWeChatSettings();
        return weChatSettings.DOMAIN_URL_vod__c;
    }
}