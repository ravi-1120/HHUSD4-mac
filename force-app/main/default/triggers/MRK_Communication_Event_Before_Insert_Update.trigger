trigger MRK_Communication_Event_Before_Insert_Update on Communication_Event_MRK__c (before insert, before update) {
	for (Communication_Event_MRK__c ce : Trigger.new) {
		ce.Version_MRK__c = (ce.Version_MRK__c == null) ? 1 : (ce.Version_MRK__c + 1);
	}
}