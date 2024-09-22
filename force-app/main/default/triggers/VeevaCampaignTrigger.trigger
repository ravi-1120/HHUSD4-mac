trigger VeevaCampaignTrigger on Campaign_vod__c(before insert, before update) {
    VeevaCampaignTriggerHandler handler = new VeevaCampaignTriggerHandler();
    handler.handleTrigger();
}