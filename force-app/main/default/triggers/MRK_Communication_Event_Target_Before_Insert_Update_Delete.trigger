trigger MRK_Communication_Event_Target_Before_Insert_Update_Delete on Communication_Event_Target_MRK__c (before insert, before update, before delete) {
	
	List<Communication_Event_Target_MRK__c> cetList = Trigger.isDelete ? Trigger.old : Trigger.new;
	
	// get all related comm events
	Set<Id> commEventIds = new Set<Id>();
	for (Communication_Event_Target_MRK__c cet : cetList) {
		commEventIds.add(cet.Communication_Event_MRK__c);
	}

	// increment the version for each related comm event
	List<Communication_Event_MRK__c> ceList = [select Id, Version_MRK__c from Communication_Event_MRK__c where Id in :commEventIds];
	for (Communication_Event_MRK__c ce : ceList) {
		ce.Version_MRK__c = (ce.Version_MRK__c == null) ? 1 : (ce.Version_MRK__c + 1);
	}
	update ceList;
}