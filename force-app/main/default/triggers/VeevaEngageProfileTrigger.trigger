trigger VeevaEngageProfileTrigger on Engage_Profile_vod__c (before insert, before update, after delete) {
    VeevaEngageProfileTriggerHandler handler = new VeevaEngageProfileTriggerHandler();
    handler.handleTrigger();
}