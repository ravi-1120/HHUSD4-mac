public with sharing class VeevaBusinessCalendarController {
    @AuraEnabled
    public static List<Calendar_Event_vod__c> getCalendarEvents() {
        return new VeevaBusinessCalendarService().getCalendarEvents();
    }

    @AuraEnabled
    public static List<MC_Cycle_vod__c> getMCCycles() {
        return new VeevaBusinessCalendarService().getMCCycles();
    }

    @AuraEnabled
    public static List<Campaign_vod__c> getCampaigns() {
        return new VeevaBusinessCalendarService().getCampaigns();
    }

    @AuraEnabled
    public static List<Account_Plan_vod__c> getAccountPlans() {
        return new VeevaBusinessCalendarService().getAccountPlans();
    }
}