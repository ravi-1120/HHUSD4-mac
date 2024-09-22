trigger MRK_Goal_Opportunity on Goal_Opportunity_MRK__c (after delete, after insert, after update, before delete, before insert, before update) {
	MRK_TriggerFactory.process(Goal_Opportunity_MRK__c.sObjectType);
}