trigger VeevaCustomerJourneyTrigger on Customer_Journey_vod__c (before insert, before update) {
    VeevaCustomerJourneyTriggerHandler handler = new VeevaCustomerJourneyTriggerHandler();
    handler.handleTrigger();
}