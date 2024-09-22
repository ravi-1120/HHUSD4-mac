trigger MRK_Communication_Event_Target on Communication_Event_Target_MRK__c (after delete, after insert, after update, before delete, before insert, before update) {
	MRK_TriggerFactory.process(Communication_Event_Target_MRK__c.sObjectType);
}