trigger VeevaTerritoryBudgetTransactionTrigger on Territory_Budget_Transaction_vod__c (after insert, after update, after delete, after undelete) {
    VeevaTriggerHandler handler = new VeevaTerrBudgetTransactionTriggerHandler();
    handler.handleTrigger();
}