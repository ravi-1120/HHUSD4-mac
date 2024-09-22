trigger VeevaCustomerJourneyStageTrigger on Customer_Journey_Stage_vod__c (before insert, before update) {
    VeevaCJStageTriggerHandler handler = new VeevaCJStageTriggerHandler();
    handler.handleTrigger();
}