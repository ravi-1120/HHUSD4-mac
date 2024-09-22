trigger VeevaCampaignActivityTrigger on Campaign_Activity_vod__c (before insert, before update) {
    
  VeevaCampaignActivityTriggerHandler handler = new VeevaCampaignActivityTriggerHandler();
  handler.handleTrigger();
}