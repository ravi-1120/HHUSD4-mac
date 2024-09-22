trigger MRK_Objective on Objective_MRK__c (after delete, after insert, after update, before delete, before insert, before update) {
	MRK_TriggerFactory.process(Objective_MRK__c.sObjectType);
}