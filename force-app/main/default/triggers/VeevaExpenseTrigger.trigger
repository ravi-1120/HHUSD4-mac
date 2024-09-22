trigger VeevaExpenseTrigger on Expense_vod__c (before update, before delete,  after insert, after update, after delete) {
	VeevaTriggerHandler handler = new VeevaExpenseTriggerHandler();
    handler.handleTrigger();
}