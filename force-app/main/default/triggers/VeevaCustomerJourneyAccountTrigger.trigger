trigger VeevaCustomerJourneyAccountTrigger on Customer_Journey_Account_vod__c (before insert, before update) {
    VeevaCJAccountTriggerHandler handler = new VeevaCJAccountTriggerHandler();
    handler.handleTrigger();
}