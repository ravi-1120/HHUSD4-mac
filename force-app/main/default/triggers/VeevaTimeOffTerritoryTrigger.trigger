trigger VeevaTimeOffTerritoryTrigger on Time_Off_Territory_vod__c (before insert, before update, before delete, after insert, after update) {
    VeevaTimeOffTerritoryTriggerHandler handler = new VeevaTimeOffTerritoryTriggerHandler();
    handler.handleTrigger();
}